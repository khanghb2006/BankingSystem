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
CREATE OR ALTER PROCEDURE dbo.sp_otp_generate_otpcode
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
                THROW 121000, 'Invalid account ID.', 1;

            -- Validate purpose
            IF dbo.fn_otp_validate_purpose_type(@purpose) = 0
                THROW 121001, 'Invalid OTP purpose.', 1;

            -- Generate random 6-digit OTP code
            -- CONVERT BIGINT truoc khi ABS: CHECKSUM tra int, ABS(-2147483648) se tran
            DECLARE @otp_code NCHAR(6) =
                RIGHT('000000' + CAST(ABS(CONVERT(BIGINT, CHECKSUM(NEWID()))) % 1000000 AS NVARCHAR(6)), 6);

            -- Set expiration time (5 minutes from now)
            DECLARE @expired_at DATETIME = DATEADD(MINUTE, 5, GETDATE());

            -- Vo hieu hoa OTP cu cung (account, purpose): cho HET HAN, KHONG cham 'verified'.
            -- (Neu set verified = 1 o day thi fn_otp_validate_verify se hieu nham la
            --  nguoi dung da nhap dung ma -> bo qua buoc nhap OTP.)
            UPDATE OTP
            SET expired_at = GETDATE()
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
                THROW 121002, 'Failed to generate OTP.', 1;

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




