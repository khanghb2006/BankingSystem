USE BankingSystem
GO

/**
    Function : fn_bank_transaction_validate_id
    Description : Validate if the bank transaction id exists in the BankTransaction table

    Input :
        + @transaction_id BIGINT : The bank transaction id to validate

    Output :
        + Returns 1 if the bank transaction id exists, otherwise returns 0
*/
CREATE OR ALTER FUNCTION fn_bank_transaction_validate_id
    (@transaction_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0

    IF EXISTS(
        SELECT 1 
        FROM BankTransaction 
        WHERE transaction_id = @transaction_id
    )
        SET @is_valid = 1

    RETURN @is_valid
END