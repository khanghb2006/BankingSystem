USE BankingSystem
GO

/* 
    Function : fn_branch_validate_id
    Description : Check if the branch ID is valid.
*/
CREATE OR ALTER FUNCTION fn_branch_validate_id
    (@branch_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Branch
        WHERE branch_id = @branch_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END