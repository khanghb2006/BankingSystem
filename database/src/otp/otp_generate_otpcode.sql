/* 
    OTP - Generate OTP Code
    Description: This script is used to generate a One-Time Password (OTP) for a specific account and purpose.
*/

USE BankingSystem
GO

/* 
    Input:
        + @account_id : The account ID for which the OTP is being generated.
        + @purpose : The purpose for which the OTP is being generated (e.g., "login", "transaction").

    Output:
        + otp_id
        + account_id
        + otp_code
        + purpose
        + expired_at
        + created_at
        + message
*/
CREATE PROCEDURE sp_otp_generate_otpcode
    @account_id BIGINT,
    @purpose VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
            -- Validate customer
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 130000, 'Invalid account ID.', 1;

            -- Validate purpose
            IF dbo.fn_otp_validate_purpose_type(@purpose) = 0
                THROW 130001, 'Invalid OTP purpose.', 1;

            -- Generate random 6-digit OTP code
            DECLARE @otp_code NCHAR(6) = 
                RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS NVARCHAR(6)), 6);
            
            -- Set expiration time (5 minutes from now)
            DECLARE @expired_at DATETIME = DATEADD(MINUTE, 5, GETDATE());

            -- Invalidate previous OTPs for the same account and purpose
            UPDATE OTP
            SET verified = 1
            WHERE account_id = @account_id 
                AND purpose = @purpose 
                AND verified = 0
                AND expired_at > GETDATE();

            -- Insert new OTP record
            INSERT INTO OTP
                (account_id , otp_code, purpose, expired_at, verified, created_at)
            VALUES
                (@account_id, @otp_code, @purpose, @expired_at, 0, GETDATE());

            IF @@ROWCOUNT = 0
                THROW 130002, 'Failed to generate OTP.', 1;

            -- Get the newly generated OTP ID
            DECLARE @otp_id BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return the generated OTP code
        SELECT 
            otp_id,
            account_id,
            otp_code,
            purpose,
            expired_at,
            created_at,
            'OTP generated successfully.' AS message
        FROM OTP
        WHERE otp_id = @otp_id;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END




