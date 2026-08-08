USE BankingSystem;
GO

/* 
    Function : validate_username
    Description : Validates if a username exists in the system
*/
CREATE OR ALTER FUNCTION fn_validate_username 
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
