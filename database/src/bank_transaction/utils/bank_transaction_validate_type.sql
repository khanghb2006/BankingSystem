USE BankingSystem
GO

/**
    Function : fn_bank_transaction_validate_type
    Description : Validate if the bank transaction type is valid

    Input :
        + @transaction_type VARCHAR(20) : The bank transaction type to validate

    Output :
        + Returns 1 if the bank transaction type is valid, otherwise returns 0
*/
CREATE OR ALTER FUNCTION fn_bank_transaction_validate_type
    (@transaction_type VARCHAR(20))
RETURNS BIT
AS
BEGIN

    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM TransactionType
        WHERE type_name = @transaction_type
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END