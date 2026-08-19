USE BankingSystem
GO

/**
    Function: fn_branch_validate_status
    Description: This function validates the status of a branch. 

    Input:
        + @status : Branch status to validate
    
    Output:
        + 1 if the status is valid, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_branch_validate_status
    (@status NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BranchStatus
        WHERE status_name = @status
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END