USE BankingSystem;
GO

/**
    Procedure: sp_employee_assign_branch
    Description: This procedure assigns a branch to an employee based on the provided account ID and branch ID.

    Input:
        + @account_id : Account ID
        + @new_branch_id : New branch ID to assign to the employee

    Output:
        + vw_EmployeeDetails : Employee profile information
*/
CREATE OR ALTER PROCEDURE sp_employee_assign_branch
    @account_id BIGINT,
    @new_branch_id NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 90030, 'Invalid account ID.', 1;

            -- Validate account role
            IF dbo.fn_account_validate_role(@account_id, 'Employee') = 0
                THROW 90031, 'Account role must be Employee.', 1;

            -- Validate new branch id
            IF dbo.fn_branch_validate_id(@new_branch_id) = 0
                THROW 90032, 'Invalid branch ID.', 1;

            -- Reject no-op transfer
            IF EXISTS (
                SELECT 1
                FROM Employee
                WHERE account_id = @account_id
                    AND branch_id = @new_branch_id
            )
                THROW 90033, 'Employee already belongs to this branch.', 1;

            -- Update employee branch assignment
            UPDATE Employee
            SET
                branch_id = @new_branch_id,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 90034, 'Failed to assign branch to employee.', 1;

        COMMIT TRANSACTION;

        -- Return updated profile information
        SELECT *,
            'Branch assigned successfully.' AS message
        FROM vw_EmployeeDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END
