USE BankingSystem;
GO

/**
    Function : fn_loan_validate_loan_officer
    Description: Validates if the given employee ID belongs to an active Loan Officer.

    Input:
        + @employee_id NCHAR(10) : The ID of the employee to be validated.

    Output:
        + Returns 1 if the employee is an active Loan Officer, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_loan_validate_loan_officer
    (@employee_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_loan_officer BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Employee
        WHERE employee_id = @employee_id
        AND position = 'Loan Officer'
        AND status = 'Active'
    )
        SET @is_loan_officer = 1;
    RETURN @is_loan_officer;
END