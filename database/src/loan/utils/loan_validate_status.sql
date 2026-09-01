USE BankingSystem;
GO

/**
    Function : fn_loan_validate_status
    Description : Validate loan_status exists in LoanStatus table.

    Input :
        + @loan_status VARCHAR(20) : The loan_status to validate.
    
    Output :
        + Returns 1 if the loan_status exists, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_loan_validate_status
    (@loan_status VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM LoanStatus
        WHERE status_name = @loan_status
    )
        SET @is_valid = 1;
        
    RETURN @is_valid;
END