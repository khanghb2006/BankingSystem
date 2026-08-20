USE BankingSystem
GO

/** 
    Function : fn_bank_account_validate_id
    Description: Validate if the bank account id exists in the database.

    Input :
        + @bank_account_id BIGINT : The bank account id to validate.

    Output :
        + Returns 1 if the bank account id exists, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_bank_account_validate_id
    (@bank_account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BankingAccount
        WHERE bank_account_id = @bank_account_id
    )
        SET @exists = 1;
    
    RETURN @exists;
END