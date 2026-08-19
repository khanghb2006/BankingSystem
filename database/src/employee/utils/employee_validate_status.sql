USE BankingSystem;
GO

/** 
    Function: fn_employee_validate_status
    Description: This function validates the status of an employee based on the provided account ID.

    Input:
        + @status : Status of the employee

    Output:
        + 1 : Valid employee status
        + 0 : Invalid employee status
*/
CREATE OR ALTER FUNCTION fn_employee_validate_status
    (@status NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM EmployeeStatus
        WHERE status_name = @status
    )
        SET @is_valid = 1;
        
    RETURN @is_valid;
END