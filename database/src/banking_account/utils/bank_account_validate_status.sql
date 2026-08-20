USE BankingSystem
GO

/**
    Function : fn_bank_account_validate_status
    Description : Validate if the provided bank account status is valid based on the BankingAccountStatus lookup table.

    Input:
        @status VARCHAR(20) - The account status to validate.
    
    Output:
        Returns 1 if the account status is valid, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_bank_account_validate_status
    (@status VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BankingAccountStatus
        WHERE status_name = @status
    )
        SET @is_valid = 1;
    
    RETURN @is_valid;
END