using BankingSystem.Api.Data;
using BankingSystem.Api.Features.Auth.Dtos;

namespace BankingSystem.Api.Features.Auth;
/*
    One method per stored procedure. It only maps rows to object : hashing, OTP delivery
        and bussiness flow belong to AuthService.
*/
public class AuthRepository
{
    private readonly StoredProcedureExecutor m_executor;

    public AuthRepository(StoredProcedureExecutor executor)
    {
        m_executor = executor;
    }

    // dbo.sp_account_register
    public async Task<AccountResponseDto> RegisterAsync (
        string username,
        string email,
        string phoneNumber,
        string passwordHash,
        CancellationToken cancellationToken)
    {
        var parameters = new Dictionary<string , object?>
        {
            ["@username"] = username,
            ["@email"] = email,
            ["@phoneNumber"] = phoneNumber,
            ["@passwordHash"] = passwordHash
        };

        var rows = await m_executor.QueryAsync(
            "dbo.sp_account_register",
            parameters,
            cancellationToken
        );

        return ToAccount(rows[0]);
    }

    // dbo.sp_generate_otpcode
    public async Task<IssuedOtp> GenerateOtpAsync(
        long accountId,
        string purpose,
        CancellationToken cancellationToken)
    {
        var parameters = new Dictionary<string , object?>
        {
            ["@accountId"] = accountId,
            ["@purpose"] = purpose
        };

        var rows = await m_executor.QueryAsync(
            "dbo.sp_generate_otpcode",
            parameters,
            cancellationToken
        );

        return ToIssuedOtp(rows[0]);
    }

    // dbo.sp_otp_verify
    public async Task<AccountResponseDto> VerifyOtpAsync(
        long accountId,
        string otpCode,
        string purpose,
        CancellationToken cancellationToken)
    {
        var parameters = new Dictionary<string , object?>
        {
            ["@accountId"] = accountId,
            ["@otpCode"] = otpCode,
            ["@purpose"] = purpose
        };

        var rows = await m_executor.QueryAsync(
            "dbo.sp_otp_verify",
            parameters,
            cancellationToken
        );

        return ToAccount(rows[0]);
    }

    // dbo.sp_account_activate: 
    public async Task<AccountResponseDto> ActivateAsync(
        long accountId,
        CancellationToken cancellationToken)
    {
        var parameters = new Dictionary<string, object?>
        {
            ["@account_id"] = accountId
        };

        var rows = await m_executor.QueryAsync(
            "dbo.sp_account_activate",
            parameters,
            cancellationToken);

        return ToAccount(rows[0]);
    }

    private static AccountResponseDto ToAccount(ResultRow row)
    {
        return new AccountResponseDto(
            AccountId: row.Get<long>("account_id"),
            Username: row.Get<string>("username"),
            Email: row.Get<string>("email"),
            PhoneNumber: row.Get<string>("phone_number"),
            Role: row.Get<string>("role"),
            Status: row.Get<string>("status"),
            CreatedAt: row.Get<DateTime>("created_at"),
            UpdatedAt: row.Get<DateTime?>("updated_at"));
    }

    private static IssuedOtp ToIssuedOtp(ResultRow row)
    {
        return new IssuedOtp(
            OtpId: row.Get<long>("otp_id"),
            ExpiresAt: row.Get<DateTime>("expired_at"),
            OtpCode: row.Get<string>("otp_code"));
    }
}