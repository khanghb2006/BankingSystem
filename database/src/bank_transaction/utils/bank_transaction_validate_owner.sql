USE BankingSystem
GO

/**
    Function : fn_bank_transaction_validate_owner
    Description : Validate if the bank transaction owner is valid

    Input :
        + @transaction_id BIGINT : The bank transaction ID to validate
        + @owner_bank_account_id BIGINT : The bank account ID of the owner to validate

    Output :
        + Returns 1 if the bank transaction owner is valid, otherwise returns 0
*/
CREATE OR ALTER FUNCTION fn_bank_transaction_validate_owner
    (@transaction_id BIGINT, @owner_bank_account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BankTransaction
        WHERE transaction_id = @transaction_id
          AND (from_bank_account_id = @owner_bank_account_id 
          OR to_bank_account_id = @owner_bank_account_id)
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END