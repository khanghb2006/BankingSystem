USE BankingSystem
GO

/* 
    Function : account_validate_phone_number
    Description : Validates if a phone number exists in the system
*/
CREATE OR ALTER FUNCTION fn_account_validate_phone_number 
    (@phone_number VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE phone_number = @phone_number
    )
        SET @exists = 1;
    RETURN @exists;
END