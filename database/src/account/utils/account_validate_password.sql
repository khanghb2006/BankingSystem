USE BankingSystem;
GO

/**
    Function : fn_account_validate_password
    Description : Validates if a password exists in the system.

    Input:
        + @account_id : The account ID to validate
        + @password : The password to validate (hashed)

    Output:
        + 1 : Password matches
        + 0 : Password does not match
*/

CREATE OR ALTER FUNCTION fn_account_validate_password
    (@account_id BIGINT, @password VARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE account_id = @account_id
            AND password_hash = @password
    )
        SET @exists = 1;
    RETURN @exists;
END