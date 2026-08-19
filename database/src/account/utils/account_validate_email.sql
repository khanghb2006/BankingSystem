USE BankingSystem;
GO

/**
    Function : fn_account_validate_email
    Description : Validates if an email exists in the system.

    Input:
        + @email : The email to validate

    Output:
        + 1 : Email exists
        + 0 : Email does not exist
*/
CREATE OR ALTER FUNCTION fn_account_validate_email 
    (@email NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE email = @email
    )
        SET @exists = 1;
    RETURN @exists;
END