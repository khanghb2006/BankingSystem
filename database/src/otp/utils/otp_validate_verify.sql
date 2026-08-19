/* 
    OTP - Validate and Verify
    Description: This stored procedure is used to validate and verify the OTP 
        with specific purpose for a user account
*/

USE BankingSystem
GO

CREATE OR ALTER FUNCTION fn_otp_validate_verify
    (@account_id BIGINT, @purpose VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @verified BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM OTP
        WHERE account_id = @account_id
            AND purpose = @purpose
            AND verified = 1
            AND expired_at > GETDATE()
    )
        SET @verified = 1;
    RETURN @verified;
END
