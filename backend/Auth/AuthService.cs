namespace Backend.Auth;

using Backend.Auth.Dto;
using Backend.Common;
using Backend.Db;
using Backend.Security;
using Microsoft.AspNetCore.Identity;

/*
    Coordinates the accound/auth stored procedures with password hasing and JWT issuance
    The flow is : validate -> call procedure -> map -> ApiResponse

    Login and change-password need one extra step the other actions
*/
public sealed class AuthService (
    StoredProcedureExecutor storedProcedureExecutor,
    PasswordHasher<object> passwordHasher,
    JwtIssuer jwtIssuer,
    ILogger<AuthService> logger)
{
    /*
        PasswordHasher<T>'s T is just a marker for its genertic API shape - it never reads any
        field off the instance we pass in
    */
    private static readonly object DummyUser = new();

    public async Task<ApiResponse<AccountResponse>> RegisterAsync(RegisterRequest request)
    {
        string passwordHash = passwordHasher.HashPassword(DummyUser , request.Password);

        Dictionary<string , object?> row = await storedProcedureExecutor.OneAsync (
            "sp_account_register",
            ("@username" , request.Username),
            ("@email" , request.Email),
            ("@phone_number" , request.PhoneNumber),
            ("@password" , passwordHash)
        );
        
        string? message = storedProcedureExecutor.Message(row);
        AccountResponse? account = MapRowToAccountResponse(row);

        return ApiResponse<AccountResponse>.Ok(message, account);
    }

    public async Task<ApiResponse<OtpResponse>> GenerateOtpAsync(GenerateOtpRequest request)
    {
        Dictionary<string , object?> row = await storedProcedureExecutor.OneAsync (
            "sp_otp_generate_otpcode",
            ("@account_id" , request.AccountId),
            ("@purpose" , request.Purpose)
        );

        string? message = storedProcedureExecutor.Message(row);
        
        long otpId = Rows.Lng(row , "otp_id")!.Value;
        DateTime expiresAt = Rows.Dt(row , "expired_at")!.Value;
        string otpCode = Rows.Str(row , "otp_code")!;

        /*
            This procedure returns the plain OTP code so it can be sent to the user - the 
                response we build below never include it.
            For now we just log it so the code visible during manual/dev testing and then 
                the real email/SMS comes later.
        */
       
        logger.LogInformation (
            "Generated OTP {OtpCode} for account {AccoundId} with purpose {Purpose}" , 
            otpCode , request.AccountId , request.Purpose);
        
        OtpResponse otp = new(otpId , expiresAt);
        return ApiResponse<OtpResponse>.Ok(message, otp);
    }

    /* 
        Verify OTP - confirm the 6-digit code the user just typed matches the one 
            sp_otp_generate_otpcode created earlier.
    */
    public async Task<ApiResponse<AccountResponse>> VerifyOtpAsync(VerifyOtpRequest request)
    {
        Dictionary<string , object?> row = await storedProcedureExecutor.OneAsync (
            "sp_otp_verify",
            ("@account_id" , request.AccountId),
            ("@otp_code" , request.OtpCode),
            ("@purpose" , request.Purpose)
        );

        string? message = storedProcedureExecutor.Message(row);
        AccountResponse? account = MapRowToAccountResponse(row);

        return ApiResponse<AccountResponse>.Ok(message, account);
    }

    /* Activate Account - flips a Pending Account to Active but only succeeds if it 'Register'
        OTP was already verified. Also deletes the now-used OTP now.
    */
    public async Task<ApiResponse<AccountResponse>> ActivateAsync(ActivateRequest request)
    {
        Dictionary<string , object?> row = await storedProcedureExecutor.OneAsync (
            "sp_account_activate",
            ("@account_id" , request.AccountId)
        );

        string? message = storedProcedureExecutor.Message(row);
        AccountResponse account = MapRowToAccountResponse(row);

        return ApiResponse<AccountResponse>.Ok(message, account);
    }

    /*
        Login - the one method that can't just hash-and-compare because the PasswordHasher salts
            every hash differently : hashing the same password twice never produces thge same string.
        So "password_hash = @password" check can't be trusted with a freshly-hashed value.

        Fix: read the stored hash first (sp_account_get_crendentials), verify it with 
            PasswordHasher ourselves then decide what to forward as @password to sp_account_login
            + correct password -> forward to the real stored hash (guaranteed match)
            + wrong password / username not found -> forward the caller's raw plaintext (can never
                equal a stored hash) so sp_account_login naturally throws its own existing error 
        
        Also logs the attempt (success or failure) via sp_login_history_create, but only when the
            username actually to an account (LoginHistory has a foreign key to Account).
    */
    public async Task<ApiResponse<LoginResponse>> LoginAsync
        (LoginRequest request , string ipAddress , string device)
    {
        List<Dictionary<string , object?>> credentialRows = await storedProcedureExecutor.CallAsync (
            "sp_account_get_credentials" , 
            ("@account_id" , null),
            ("@username" , request.Username)
        );

        string passwordToSendToProc = request.Password;
        bool accountWasFound = credentialRows.Count > 0;

        if (accountWasFound)
        {
            string storedPasswordHash = Rows.Str(credentialRows[0] , "password_hash")!;
            PasswordVerificationResult verifyResult = 
                passwordHasher.VerifyHashedPassword(DummyUser , storedPasswordHash , request.Password);

            if (verifyResult != PasswordVerificationResult.Failed)
                passwordToSendToProc = storedPasswordHash; // guaranteed match, so the proc's own password check passes
        }

        Dictionary<string , object?> accountRow;
        string loginStatus = "Failed";

        try
        {
            accountRow = await storedProcedureExecutor.OneAsync (
                "sp_account_login",
                ("@username" , request.Username),
                ("@password" , passwordToSendToProc)
            );

            loginStatus = "Successful";
        }
        finally
        {
            if (accountWasFound)
            {
                long attemptedAccountId = Rows.Lng(credentialRows[0] , "account_id")!.Value;
                await storedProcedureExecutor.CallAsync(
                    "sp_login_history_create",
                    ("@account_id" , attemptedAccountId),
                    ("@ip_address" , ipAddress),
                    ("@device" , device),
                    ("@login_status" , loginStatus)
                );
            }
        }

        string? message = storedProcedureExecutor.Message(accountRow);
        AccountResponse account = MapRowToAccountResponse(accountRow);
        string token = jwtIssuer.Issue(account.AccountId , account.Username , account.Role);

        return ApiResponse<LoginResponse>.Ok(message, new LoginResponse(token , account));
    }

    /* 
        Change Password - same forwarding trick as LoginAsync applies to two password

        Old password is verified with PasswordHasher against the stored hash, then
            + Correct -> forward the real stored hash password
            + Wrong / Account no found -> forward the raw plaintext (never matches)

        New password normally hashed fresh. Two salted hashes of the same password never 
            compare equal and rule would silently never trigger
    */
    public async Task<ApiResponse<PasswordUpdateResponse>> ChangePasswordAsync
        (long accountId , ChangePasswordRequest request)
    {
        List<Dictionary<string , object?>> credentialRows = await storedProcedureExecutor.CallAsync (
            "sp_account_get_credentials" , 
            ("@account_id" , accountId),
            ("@username" , null)
        );

        string oldPasswordToSendToProc = request.OldPassword;
        string newPasswordToSendToProc = passwordHasher.HashPassword(DummyUser , request.NewPassword);

        if (credentialRows.Count > 0)
        {
            string storedPasswordHash = Rows.Str(credentialRows[0] , "password_hash")!;

            PasswordVerificationResult oldResult = 
                passwordHasher.VerifyHashedPassword(DummyUser , storedPasswordHash , request.OldPassword);

            if (oldResult != PasswordVerificationResult.Failed)
            {
                oldPasswordToSendToProc = storedPasswordHash;

                PasswordVerificationResult sameResult = 
                    passwordHasher.VerifyHashedPassword(DummyUser , storedPasswordHash , request.NewPassword);

                if (sameResult != PasswordVerificationResult.Failed)
                    newPasswordToSendToProc = storedPasswordHash; // same password, so forward the stored hash
            }
        }
        Dictionary<string , object?> row = await storedProcedureExecutor.OneAsync (
            "sp_account_change_password",
            ("@account_id" , accountId),
            ("@old_password" , oldPasswordToSendToProc),
            ("@new_password" , newPasswordToSendToProc)
        );

        string? message = storedProcedureExecutor.Message(row);
        long updatedAccountId = Rows.Lng(row , "account_id")!.Value;
        DateTime updatedAt = Rows.Dt(row , "updated_at")!.Value;

        return ApiResponse<PasswordUpdateResponse>.Ok(message, new PasswordUpdateResponse(updatedAccountId , updatedAt));
    }

    /*
        Convert one raw database row (a row of vw_Account plus message column) into a typed
            AccountResponse
        Shared by Register , VerifyOtp, Activate and Login because all 4 stored procedures 
            return the same vw_Account shape
    */
    private static AccountResponse MapRowToAccountResponse(Dictionary<string , object?> row)
    {
        // The required columns are never NULL in vw_Account so '!' is safe here
        long accountId = Rows.Lng(row , "account_id")!.Value;
        string username = Rows.Str(row , "username")!;
        string email = Rows.Str(row , "email")!;
        string phoneNumber = Rows.Str(row , "phone_number")!;
        string role = Rows.Str(row , "role")!;
        string status = Rows.Str(row , "status")!;

        // Timestamps stay nullable to match AccountResponse (DateTime?)
        DateTime? createdAt = Rows.Dt(row , "created_at");
        DateTime? updatedAt = Rows.Dt(row , "updated_at");

        // Argument order must follow the AccountResponse constructor exactly
        return new AccountResponse(accountId , username , email , phoneNumber , 
            role , createdAt , updatedAt , status);
    }
}
