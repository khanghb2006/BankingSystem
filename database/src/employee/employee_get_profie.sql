USE BankingSystem;
GO

/** 
    Procedure: sp_employee_get_profile
    Description: This procedure retrieves the profile information of an employee based on the provided account ID.

    Input:
        + @account_id : Account ID

    Output:
        + vw_EmployeeDetails : Employee profile information
*/
CREATE OR ALTER PROCEDURE sp_employee_get_profile
    @account_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validate account
        IF dbo.fn_account_validate_id(@account_id) = 0
            THROW 90040, 'Invalid account ID.', 1;

        -- Validate account role
        IF dbo.fn_account_validate_role(@account_id, 'Employee') = 0
            THROW 90041, 'Account role must be Employee.', 1;

        -- Retrieve employee profile information
        SELECT *
        FROM vw_EmployeeDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END