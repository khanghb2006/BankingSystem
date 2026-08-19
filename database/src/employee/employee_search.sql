/*
    Employee - Search
    Description: This procedure looks up employees by citizen_id and/or full_name.
        Used for admin/HR lookups.
*/

USE BankingSystem;
GO

/*
    Input:
        + @citizen_id : Exact citizen ID to search for (optional).
        + @full_name : Partial or full employee name to search for (optional).

    Output:
        + vw_EmployeeSummary rows matching the given criteria

    Note :
        + At least one of @citizen_id or @full_name must be provided.
        + @citizen_id is matched exactly; @full_name is matched as a partial (contains) search.
*/
CREATE OR ALTER PROCEDURE sp_employee_search
    @citizen_id VARCHAR(20) = NULL,
    @full_name NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @citizen_id IS NULL AND @full_name IS NULL
            THROW 90060, 'At least one of citizen_id or full_name must be provided.', 1;

        SELECT S.*
        FROM vw_EmployeeSummary S
        JOIN Employee E ON E.employee_id = S.employee_id
        WHERE (@citizen_id IS NULL OR E.citizen_id = @citizen_id)
            AND (@full_name IS NULL OR E.full_name LIKE '%' + @full_name + '%')
        ORDER BY E.full_name;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
