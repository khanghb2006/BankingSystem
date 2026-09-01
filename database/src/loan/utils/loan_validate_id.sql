USE BankingSystem
GO

/**
    Function : fn_loan_validate_id
    Description : Validate loan_id exists in Loan table.

    Input :
        + @loan_id BIGINT : The loan_id to validate.
    
    Output :
        + Returns 1 if the loan_id exists, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_loan_validate_id
    (@loan_id BIGINT)
RETURNS BIT
AS 
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Loan
        WHERE loan_id = @loan_id
    )
        SET @is_valid = 1;
        
    RETURN @is_valid;
END