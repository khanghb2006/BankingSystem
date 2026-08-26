USE BankingSystem;
GO

/**
    Function : fn_beneficiary_validate_owner
    Description : This function validates whether a beneficiary belongs to a specific customer.

    Input: 
        + @beneficiary_id BIGINT
        + @customer_id BIGINT
    
    Output:
        + 1 if the beneficiary belongs to the customer, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_beneficiary_validate_owner
    (@beneficiary_id BIGINT, @customer_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_owner BIT = 0;

    IF EXISTS (
        SELECT 1 
        FROM Beneficiary 
        WHERE beneficiary_id = @beneficiary_id 
            AND customer_id = @customer_id
    )
        SET @is_owner = 1;

    RETURN @is_owner;
END;