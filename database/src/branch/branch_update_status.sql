USE BankingSystem;
GO

/** 
    Procedure: sp_branch_update_status
    Description: This procedure updates the status of a branch in the system.

    Input:
        + @branch_id : Branch ID
        + @status : New status for the branch

    Output:
        + vw_Branch : Branch information
*/
CREATE OR ALTER PROCEDURE sp_branch_update_status
    @branch_id NCHAR(10),
    @new_status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate branch_id
            IF dbo.fn_branch_validate_id(@branch_id) = 0
                THROW 40000, 'Invalid branch ID.', 1;

            -- Validate status
            IF dbo.fn_branch_validate_status(@new_status) = 0
                THROW 40001, 'Invalid status.', 1;

            -- Update branch status
            UPDATE Branch
            SET 
                status = @new_status,
                updated_at = GETDATE()
            WHERE branch_id = @branch_id;

            IF @@ROWCOUNT = 0
                THROW 40002, 'Failed to update branch status.', 1;

        COMMIT TRANSACTION;

        -- Return updated branch information
        SELECT *,
            'Branch status updated successfully.' AS message
        FROM vw_Branch
        WHERE branch_id = @branch_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END