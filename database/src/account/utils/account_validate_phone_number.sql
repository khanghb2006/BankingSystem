USE BankingSystem
GO

/**
    Function : fn_account_validate_phone_number
    Description : Validates if a phone number exists in the system.

    Input:
        + @phone_number : The phone number to validate

    Output:
        + 1 : Phone number exists
        + 0 : Phone number does not exist
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