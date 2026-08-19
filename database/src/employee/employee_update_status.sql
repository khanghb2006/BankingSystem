USE BankingSystem;
GO

/**
    Procedure: sp_employee_update_status
    Description: This procedure updates the status of an employee based on the provided account ID.

    Input:
        + @account_id : Account ID
        + @new_status : New status of the employee
    
    Output:
        + vw_EmployeeDetails : Employee profile information
*/
CREATE OR ALTER PROCEDURE sp_employee_update_status
    @account_id BIGINT,
    @new_status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 90050, 'Invalid account ID.', 1;

            -- Validate account role
            IF dbo.fn_account_validate_role(@account_id, 'Employee') = 0
                THROW 90051, 'Account role must be Employee.', 1;

            -- Validate new status
            IF dbo.fn_employee_validate_status(@new_status) = 0
                THROW 90052, 'Invalid status.', 1;

            -- Update employee status
            UPDATE Employee
            SET
                status = @new_status,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 90053, 'Failed to update employee status.', 1;

        COMMIT TRANSACTION;

        -- Return updated profile information
        SELECT *,
            'Status updated successfully.' AS message
        FROM vw_EmployeeDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END