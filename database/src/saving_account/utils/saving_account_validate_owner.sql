USE BankingSystem;
GO

/**
    Function : fn_saving_account_validate_owner
    Description : Validate the customer owns the saving account with the given
        saving_id. Ownership is derived from the source banking account.

    Input :
        + @saving_id BIGINT : The saving_id to validate.
        + @customer_id NCHAR(10) : The customer_id to validate.

    Output :
        + Returns 1 if the customer owns the saving account, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_saving_account_validate_owner
    (@saving_id BIGINT, @customer_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM SavingAccount SA
        JOIN BankingAccount BA ON SA.source_bank_account_id = BA.bank_account_id
        WHERE SA.saving_id = @saving_id
            AND BA.customer_id = @customer_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
