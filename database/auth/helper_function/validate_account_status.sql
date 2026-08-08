USE BankingSystem;
GO

/* 
    Function: validate_account_status
    Description: Validates if an account is specific @status
*/
CREATE OR ALTER FUNCTION fn_validate_account_status 
    (@username VARCHAR(50), @status NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE username = @username AND status = @status
    )
        SET @exists = 1;
    RETURN @exists;
END 