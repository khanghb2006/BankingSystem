USE BankingSystem;
GO

/*
    Function : validate_password
    Description : Validates if a password exists in the system
*/

CREATE OR ALTER FUNCTION fn_validate_password 
    (@username VARCHAR(50) , @password VARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE username = @username 
            AND password_hash = @password
    )
        SET @exists = 1;
    RETURN @exists;
END