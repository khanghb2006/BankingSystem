USE BankingSystem
GO

/**
    Procedure: sp_branch_update 
    Description: This procedure retrieves information about a specific branch based on the provided branch ID.

    Input:
        + @branch_id : Branch ID
        + @branch_name : Name of the branch
        + @address : Address of the branch
        + @phone_number : Phone number of the branch
    
    Output:
        + vw_Branch : Branch information
*/
CREATE OR ALTER PROCEDURE sp_branch_update
    @branch_id NCHAR(10),
    @branch_name NVARCHAR(100) NULL,
    @address NVARCHAR(100) NULL,
    @phone_number NVARCHAR(20) NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate branch_id
            IF dbo.fn_branch_validate_id(@branch_id) = 0
                THROW 30000, 'Invalid branch ID.', 1;

            -- Update branch information
            UPDATE Branch
            SET 
                branch_name = COALESCE(@branch_name, branch_name),
                address = COALESCE(@address, address),
                phone_number = COALESCE(@phone_number, phone_number),
                updated_at = GETDATE()
            WHERE branch_id = @branch_id;

            IF @@ROWCOUNT = 0
                THROW 30001, 'Failed to update branch information.', 1;

        COMMIT TRANSACTION;

        -- Return updated branch information
        SELECT *,
            'Branch updated successfully.' AS message
        FROM vw_Branch
        WHERE branch_id = @branch_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
