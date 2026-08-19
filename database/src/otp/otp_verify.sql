/* 
    Authentication: Verify OTP
    Description: This stored procedure is used to verify the OTP 
        with specific purpose for a user account
*/

USE BankingSystem
GO

/* 
    Input:
        @account_id : The account ID of the user.
        @otp_code : The OTP provided by the user.
        @purpose : The purpose of the OTP (e.g., 'Register', 'PasswordReset').

    Output:
        + account_id
        + username
        + email
        + phone_number
        + role 
        + status
        + message
    
    Note : 
        + The OTP should be hashed before calling this stored procedure.
*/
CREATE OR ALTER PROCEDURE sp_otp_verify
    @account_id BIGINT,
    @otp_code NCHAR(6),
    @purpose VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account existence
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 20000, 'Account does not exist.', 1;

            -- Validate OTP code matches an unverified, unexpired record
            IF dbo.fn_otp_validate_purpose(@account_id, @otp_code, @purpose) = 0
                THROW 30001, 'Invalid or Expired OTP code.', 1;

            -- Marked OTP as verified
            UPDATE OTP
                SET verified = 1
            WHERE account_id = @account_id
                AND otp_code = @otp_code
                AND purpose = @purpose
                AND verified = 0
                AND expired_at > GETDATE();

            -- Activate pending account
            IF @purpose = 'Register'
            BEGIN
                UPDATE Account
                SET 
                    status = 'Active',
                    updated_at = GETDATE()
                WHERE account_id = @account_id
                    AND status = 'Pending';
            END

            -- Return verification result
            SELECT *,
                'OTP verification successful' AS message
            FROM vw_Account
            WHERE account_id = @account_id

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
