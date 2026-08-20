USE BankingSystem
GO

/**
    Function : fn_bank_account_validate_owner
    Description: Validate if the provided account is belongs to the exact owner

    Input : 
        + @bank_account_id BIGINT
        + customer_id NCHAR(10)

    Output :
        Returns 1 if the account belongs to the customer, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_bank_account_validate_owner
    (@bank_account_id BIGINT, @customer_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_owner BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BankingAccount
        WHERE bank_account_id = @bank_account_id 
        AND customer_id = @customer_id
    )
        SET @is_owner = 1;
    RETURN @is_owner;
END