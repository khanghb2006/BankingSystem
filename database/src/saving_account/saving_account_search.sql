USE BankingSystem;
GO

/**
    Procedure : sp_saving_account_search
    Description : Search saving accounts by various criteria.

    Input:
        + @customer_id NCHAR(10) : customer ID to filter by (optional).
        + @status VARCHAR(20) : saving account status to filter by (optional).
        + @from_date DATE : filter by start_date >= @from_date (optional).
        + @to_date DATE : filter by start_date <= @to_date (optional).

    Output:
        + vw_SavingAccountDetails rows matching the criteria.

    Note:
        + At least one of @customer_id or @status must be provided.
*/
CREATE OR ALTER PROCEDURE dbo.sp_saving_account_search
    @customer_id NCHAR(10) = NULL,
    @status VARCHAR(20) = NULL,
    @from_date DATE = NULL,
    @to_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Must have at least one of @customer_id or @status
        IF @customer_id IS NULL AND @status IS NULL
            THROW 352000, 'At least one search criteria must be provided.', 1;

        -- Validate customer ID
        IF @customer_id IS NOT NULL AND dbo.fn_customer_validate_id(@customer_id) = 0
            THROW 352010, 'Invalid customer ID.', 1;

        -- Validate status
        IF @status IS NOT NULL AND dbo.fn_saving_account_validate_status(@status) = 0
            THROW 352020, 'Invalid saving account status.', 1;

        -- Validate date range
        IF @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date > @to_date
            THROW 352030, 'Invalid date range. From date must be less than or equal to To date.', 1;

        -- Return the saving accounts matching the criteria
        SELECT *
        FROM vw_SavingAccountDetails
        WHERE (@customer_id IS NULL OR customer_id = @customer_id)
            AND (@status IS NULL OR status = @status)
            AND (@from_date IS NULL OR start_date >= @from_date)
            AND (@to_date IS NULL OR start_date <= @to_date)
        ORDER BY start_date DESC, saving_id DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
