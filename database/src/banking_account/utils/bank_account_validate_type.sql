USE BankingSystem
GO

/**
    Function : fn_bank_account_validate_type
    Description : Validate if the provided account type is valid based on the BankingAccountType lookup table.

    Input:
        @account_type VARCHAR(20) - The account type to validate.
    
    Output:
        Returns 1 if the account type is valid, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_bank_account_validate_type
    (@account_type VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BankingAccountType
        WHERE type_name = @account_type
    )
        SET @is_valid = 1;
    
    RETURN @is_valid;
END