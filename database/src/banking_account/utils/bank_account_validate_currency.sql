USE BankingSystem
GO

/**
    Function : fn_bank_account_validate_currency
    Description : Validate if the provided currency is valid based on the BankingAccountCurrency lookup table.

    Input:
        @currency NVARCHAR(10) - The currency to validate.
    
    Output:
        Returns 1 if the currency is valid, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_bank_account_validate_currency
    (@currency NVARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Currency
        WHERE currency_code = @currency
    )
        SET @is_valid = 1;
    
    RETURN @is_valid;
END