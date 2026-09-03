USE BankingSystem;
GO

/**
    Procedure: sp_employee_update_position
    Description: This procedure updates the position of an employee based on the provided account ID.

    Input:
        + @account_id : Account ID
        + @new_position : New position of the employee

    Output:
        + vw_EmployeeDetails : Employee profile information
*/
CREATE OR ALTER PROCEDURE dbo.sp_employee_update_position
    @account_id BIGINT,
    @new_position VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 85000, 'Invalid account ID.', 1;

            -- Validate account role
            IF dbo.fn_account_validate_role(@account_id, 'Employee') = 0
                THROW 85001, 'Account role must be Employee.', 1;

            -- Validate new position
            IF dbo.fn_employee_validate_position(@new_position) = 0
                THROW 85002, 'Invalid position.', 1;

            -- Update employee position
            UPDATE Employee
            SET
                position = @new_position,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 85003, 'Failed to update employee position.', 1;

        COMMIT TRANSACTION;

        -- Return updated profile information
        SELECT *,
            'Position updated successfully.' AS message
        FROM vw_EmployeeDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END
