USE BankingSystem;
GO

/**
    Procedure: sp_branch_create
    Description: This procedure creates a new branch in the system.

    Input:
        + @branch_name : Name of the branch
        + @address : Address of the branch
        + @phone_number : Phone number of the branch
    
    Output:
        + vw_Branch : Branch information
*/
CREATE OR ALTER PROCEDURE sp_branch_create
    @branch_name NVARCHAR(100),
    @address NVARCHAR(100),
    @phone_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate branch_name
            IF @branch_name IS NULL OR LEN(@branch_name) = 0
                THROW 20000, 'Branch name cannot be empty.', 1;
            
            IF @address IS NULL OR LEN(@address) = 0
                THROW 20001, 'Address cannot be empty.', 1;
            
            IF @phone_number IS NULL OR LEN(@phone_number) = 0
                THROW 20002, 'Phone number cannot be empty.', 1;

            -- Generate a unique branch_id
            DECLARE @branch_id NCHAR(10) = 'BR' + 
                RIGHT('00000000' + CAST(NEXT VALUE FOR seq_BranchID AS NVARCHAR(8)), 8);

            -- Insert new branch into the Branch table
            INSERT INTO Branch 
                (branch_id, branch_name, address, phone_number , created_at, status)
            VALUES 
                (@branch_id, @branch_name, @address, @phone_number, GETDATE(), 'Active');

            IF @@ROWCOUNT = 0
                THROW 20003, 'Failed to create branch.', 1;

        COMMIT TRANSACTION;
        -- Return message and branch information
            SELECT *,
                'Branch created successfully.' AS message
            FROM vw_Branch
            WHERE branch_id = @branch_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END
        