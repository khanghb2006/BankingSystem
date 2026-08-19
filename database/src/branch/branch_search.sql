USE BankingSystem;
GO

/**
    Procedure: sp_branch_search
    Description: This procedure searches/lists branches by name and/or status.
        Used for branch listing screens and branch-selection dropdowns.

    Input:
        + @branch_name : Partial or full branch name to search for (optional)
        + @status : Branch status to filter by (optional)

    Output:
        + vw_Branch rows matching the given criteria

    Note :
        + Both parameters are optional; calling with no parameters returns all branches.
        + @branch_name is matched as a partial (contains) search.
*/
CREATE OR ALTER PROCEDURE sp_branch_search
    @branch_name NVARCHAR(100) = NULL,
    @status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validate status
        IF @status IS NOT NULL AND dbo.fn_branch_validate_status(@status) = 0
            THROW 50000, 'Invalid status.', 1;

        SELECT *
        FROM vw_Branch
        WHERE (@branch_name IS NULL OR branch_name LIKE '%' + @branch_name + '%')
            AND (@status IS NULL OR status = @status)
        ORDER BY branch_name;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
