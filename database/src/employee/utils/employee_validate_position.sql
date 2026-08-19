USE BankingSystem;
GO

/** 
    Function : fn_employee_validate_position
    Description : Validate position of employee

    Input:
        + @position : Position of the employee
    
    Output:
        + 0 : Valid position
        + 1 : Invalid position
*/
CREATE OR ALTER FUNCTION fn_employee_validate_position
    (@position VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM EmployeePosition
        WHERE @position = position_name
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
