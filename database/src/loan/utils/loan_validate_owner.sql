USE BankingSystem;
GO

/**
    Function : fn_loan_validate_owner
    Description : Validate customer owns the loan with the given loan_id.

    Input :
        + @loan_id BIGINT : The loan_id to validate.
        + @customer_id NCHAR(10) : The customer_id to validate.
    
    Output :
        + Returns 1 if the customer owns the loan, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_loan_validate_owner
    (@loan_id BIGINT, @customer_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Loan
        WHERE loan_id = @loan_id 
            AND customer_id = @customer_id
    )
        SET @is_valid = 1;
        
    RETURN @is_valid;
END