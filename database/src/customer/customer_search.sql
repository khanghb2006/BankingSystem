/*
    Customer - Search
    Description: This procedure looks up customers by citizen_id and/or full_name.
        Used by employees for counter/service lookups.
*/

USE BankingSystem;
GO

/*
    Input:
        + @citizen_id : Exact citizen ID to search for (optional).
        + @full_name : Partial or full customer name to search for (optional).

    Output:
        + vw_CustomerSummary rows matching the given criteria

    Note :
        + At least one of @citizen_id or @full_name must be provided.
        + @citizen_id is matched exactly; @full_name is matched as a partial (contains) search.
*/
CREATE OR ALTER PROCEDURE sp_customer_search
    @citizen_id VARCHAR(20) = NULL,
    @full_name NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @citizen_id IS NULL AND @full_name IS NULL
            THROW 50045, 'At least one of citizen_id or full_name must be provided.', 1;

        SELECT S.*
        FROM vw_CustomerSummary S
        JOIN Customer C ON C.customer_id = S.customer_id
        WHERE (@citizen_id IS NULL OR C.citizen_id = @citizen_id)
            AND (@full_name IS NULL OR C.full_name LIKE '%' + @full_name + '%')
        ORDER BY C.full_name;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
