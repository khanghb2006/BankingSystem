USE BankingSystem
GO

/*
    Function : fn_employee_validate_exists
    Description : Check if an employee profile already exists for the given account.
*/
CREATE OR ALTER FUNCTION fn_employee_validate_exists
    (@account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Employee
        WHERE account_id = @account_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
