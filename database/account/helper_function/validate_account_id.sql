USE BankingSystem
GO

/*
    Function : fn_validate_account_id
    Description: This function is used to validate the account ID.
*/
CREATE OR ALTER FUNCTION fn_validate_account_id
    (@account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    -- Check if the provided account ID exists in the Account table
    IF EXISTS (
        SELECT 1
        FROM Account
        WHERE account_id = @account_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END