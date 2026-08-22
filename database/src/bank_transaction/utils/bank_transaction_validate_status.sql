USE BankingSystem
GO

/** 
    Function : fn_bank_transaction_validate_status
    Description : Validate if the bank transaction status is valid

    Input :
        + @transaction_status VARCHAR(20) : The bank transaction status to validate

    Output :
        + Returns 1 if the bank transaction status is valid, otherwise returns 0
*/
CREATE OR ALTER FUNCTION fn_bank_transaction_validate_status
    (@transaction_status NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM TransactionStatus
        WHERE status_name = @transaction_status
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END