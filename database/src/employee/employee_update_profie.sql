USE BankingSystem;
GO

/**
    Procedure: sp_employee_update_profile
    Description: This procedure updates the profile information of an employee based on the provided account ID.

    Input:
        + @account_id : Account ID
        + @full_name : New full name (optional)
        + @dob : New date of birth (optional)
        + @gender : New gender (optional)
        + @address : New address (optional)

    Output:
        + vw_EmployeeDetails : Updated employee profile information
        + message : Success or Failure message

    Note :
        + Branch reassignment is handled separately by sp_employee_assign_branch.
        + Only provided fields will be updated, others will remain unchanged.
*/
CREATE OR ALTER PROCEDURE sp_employee_update_profile
    @account_id BIGINT,
    @full_name NVARCHAR(100) = NULL,
    @dob DATE = NULL,
    @gender VARCHAR(10) = NULL,
    @address NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 90010, 'Invalid account ID.', 1;

            -- Validate account role
            IF dbo.fn_account_validate_role(@account_id, 'Employee') = 0
                THROW 90011, 'Account role must be Employee.', 1;

            -- Check whether there is anything to update
            IF @full_name IS NULL
                AND @dob IS NULL
                AND @gender IS NULL
                AND @address IS NULL
                THROW 90012, 'No fields provided for update.', 1;

            -- Update employee profile
            UPDATE Employee
            SET
                full_name = COALESCE(@full_name, full_name),
                dob = COALESCE(@dob, dob),
                gender = COALESCE(@gender, gender),
                address = COALESCE(@address, address),
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 90013, 'Failed to update employee profile.', 1;

        COMMIT TRANSACTION;

        -- Return message and updated profile information
        SELECT *,
            'Employee profile updated successfully.' AS message
        FROM vw_EmployeeDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
