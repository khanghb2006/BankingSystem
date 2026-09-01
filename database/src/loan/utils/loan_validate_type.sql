USE BankingSystem;
GO

/** 
    Function : fn_loan_validate_type
    Description : Validate loan_type exists in LoanType table.

    Input :
        + @loan_type VARCHAR(20) : The loan_type to validate.
    
    Output :
        + Returns 1 if the loan_type exists, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_loan_validate_type
    (@loan_type VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM LoanType
        WHERE type_name = @loan_type
    )
        SET @is_valid = 1;
        
    RETURN @is_valid;
END