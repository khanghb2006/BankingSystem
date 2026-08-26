USE BankingSystem;
GO

/** 
    Function : fn_beneficiary_validate_duplicate
    Description : This function checks if a beneficiary with the same bank account ID already exists for a specific customer.

    Input: 
        + @customer_id NCHAR(10)
        + @bank_account_id BIGINT

    Output:
        + 1 if a duplicate beneficiary exists, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_beneficiary_validate_duplicate
    (@customer_id NCHAR(10), @bank_account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_duplicate BIT = 0;

    IF EXISTS (
        SELECT 1 
        FROM Beneficiary 
        WHERE customer_id = @customer_id 
            AND bank_account_id = @bank_account_id
    )
        SET @is_duplicate = 1;

    RETURN @is_duplicate;
END;