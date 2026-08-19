/*
    Customer - Assign Branch
    Description: This procedure transfers a customer to a different branch.
        Performed by an employee (e.g. counter staff, branch admin).
*/

USE BankingSystem;
GO

/*
    Input:
        + @customer_id : The unique identifier of the customer to transfer.
        + @new_branch_id : The branch to assign the customer to.
        + @employee_id : The employee performing the transfer.

    Output:
        + vw_CustomerDetails row for the updated customer
        + message

    Note :
        + Customer cannot be assigned to the branch they already belong to.
*/
CREATE OR ALTER PROCEDURE sp_customer_assign_branch
    @customer_id NCHAR(10),
    @new_branch_id NCHAR(10),
    @employee_id NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate customer id
            IF dbo.fn_customer_validate_id(@customer_id) = 0
                THROW 50040, 'Invalid customer_id. Customer does not exist.', 1;

            -- Validate employee id
            IF dbo.fn_employee_validate_id(@employee_id) = 0
                THROW 50041, 'Invalid employee_id. Employee does not exist.', 1;

            -- Validate new branch id
            IF dbo.fn_branch_validate_id(@new_branch_id) = 0
                THROW 50042, 'Invalid new_branch_id. Branch does not exist.', 1;

            -- Reject no-op transfer
            IF dbo.fn_customer_validate_branch(@customer_id, @new_branch_id) = 1
                THROW 50043, 'Customer already belongs to this branch.', 1;

            -- Transfer customer to the new branch
            UPDATE Customer
            SET
                branch_id = @new_branch_id,
                updated_at = GETDATE()
            WHERE customer_id = @customer_id;

            IF @@ROWCOUNT = 0
                THROW 50044, 'Failed to assign customer to branch.', 1;

        COMMIT TRANSACTION;

        -- Return the updated customer profile
        SELECT *,
            'Customer branch assigned successfully.' AS message
        FROM vw_CustomerDetails
        WHERE customer_id = @customer_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
