USE BankingSystem;
GO

/* 
    Function: validate_email
    Description: Validates if an email exists in the system
*/
CREATE OR ALTER FUNCTION fn_validate_email 
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