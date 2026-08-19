USE BankingSystem;
GO

/**
    Function : fn_employee_validate_citizen_id
    Description : Validate citizen id of employee

    Input:
        + @citizen_id : Citizen ID of the employee
    
    Output:
        + 0 : Valid citizen id
        + 1 : Citizen id is already exists in the database
*/
CREATE OR ALTER FUNCTION fn_employee_validate_citizen_id
    (@citizen_id VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Employee
        WHERE citizen_id = @citizen_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END