USE BankingSystem;
GO

/**
    Function : fn_account_validate_username
    Description : Validates if a username exists in the system.

    Input:
        + @username : The username to validate

    Output:
        + 1 : Username exists
        + 0 : Username does not exist
*/
CREATE OR ALTER FUNCTION fn_account_validate_username 
    (@username VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE username = @username
    )
        SET @exists = 1;
    RETURN @exists;
END
