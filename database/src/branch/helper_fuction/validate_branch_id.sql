USE BankingSystem
GO

/* 
    Function : fn_validate_branch_id
    Description : Check if the branch ID is valid.
*/
CREATE OR ALTER FUNCTION fn_validate_branch_id
    (@branch_id BIGINT)
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