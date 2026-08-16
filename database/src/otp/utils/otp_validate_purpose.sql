/* 
    Function : fn_otp_validate_purpose
    Description: This function is used to validate the OTP purpose.
*/
USE BankingSystem
GO

CREATE OR ALTER FUNCTION fn_otp_validate_purpose
    (@account_id BIGINT, @otp_code NCHAR(6), @purpose VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    -- Check if the provided purpose exists in the OTPPurpose table
    IF EXISTS (
        SELECT 1
        FROM OTPPurpose
        JOIN OTP ON purpose_name = purpose
        WHERE account_id = @account_id
            AND purpose_name = @purpose
            AND otp_code = @otp_code
            AND verified = 0
            AND expired_at > GETDATE()
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
