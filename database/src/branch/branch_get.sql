USE BankingSystem
GO

/**
    Procedure: sp_branch_get
    Description: This procedure retrieves information about a specific branch based on the provided branch ID.

    Input:
        + @branch_id : Branch ID
    
    Output:
        + vw_Branch : Branch information
*/
CREATE OR ALTER PROCEDURE sp_branch_get_info
    @branch_id NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validate branch ID
        IF dbo.fn_branch_validate_id(@branch_id) = 0
            THROW 30000, 'Invalid branch ID.', 1;

        -- Retrieve branch information
        SELECT *
        FROM vw_Branch
        WHERE branch_id = @branch_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END