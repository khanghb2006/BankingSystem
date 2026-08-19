USE BankingSystem
GO

/*
    Function : fn_employee_validate_id
    Description : Check if the employee id is valid.
*/
CREATE OR ALTER FUNCTION fn_employee_validate_id
    (@employee_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Employee
        WHERE employee_id = @employee_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
