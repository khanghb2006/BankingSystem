USE BankingSystem
GO

/*
    Function : fn_otp_validate_purpose_type
    Description : Check if the given purpose is a recognized, active OTP purpose.
*/
CREATE OR ALTER FUNCTION fn_otp_validate_purpose_type
    (@purpose VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM OTPPurpose
        WHERE purpose_name = @purpose
            AND is_active = 1
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
