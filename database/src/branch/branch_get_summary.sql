USE BankingSystem;
GO

/**
    Procedure: sp_branch_get_summary
    Description: This procedure retrieves branch information along with aggregated
        statistics, used for the branch management dashboard.

    Input:
        + @branch_id : Branch ID

    Output:
        + branch_id
        + branch_name
        + address
        + phone_number
        + status
        + number_of_employees
        + number_of_customers
*/
CREATE OR ALTER PROCEDURE sp_branch_get_summary
    @branch_id NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validate branch id
        IF dbo.fn_branch_validate_id(@branch_id) = 0
            THROW 60000, 'Invalid branch ID.', 1;

        SELECT
            B.branch_id,
            B.branch_name,
            B.address,
            B.phone_number,
            B.status,

            -- Number of employees
            (
                SELECT COUNT(*)
                FROM Employee E
                WHERE E.branch_id = B.branch_id
            ) AS number_of_employees,

            -- Number of customers
            (
                SELECT COUNT(*)
                FROM Customer C
                WHERE C.branch_id = B.branch_id
            ) AS number_of_customers
        FROM Branch B
        WHERE B.branch_id = @branch_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
