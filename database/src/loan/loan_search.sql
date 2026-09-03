USE BankingSystem;
GO

/** 
    Proceduere : sp_loan_search
    Description : This procedure is used to search for loans based on various criteria.

    Input:
        + @customer_id NCHAR(10) : customer ID to filter loans (optional).
        + @loan_type VARCHAR(20) : loan type to filter loans (optional).
        + @status VARCHAR(20) : loan status to filter loans (optional).
        + approved_by NCHAR(10) : employee ID who approved the loan to filter loans (optional).
        + @from_date DATE : start date to filter loans based on their start date (optional).
        + @to_date DATE : end date to filter loans based on their start date (optional).

    Output:
        + vw_LoanDetails : A view that provides details of the loans matching the search criteria.
    
    Note:
        + Must have at least one search criteria in @customer_id, @status or @approved_by
*/
CREATE OR ALTER PROCEDURE dbo.sp_loan_search
    @customer_id NCHAR(10) = NULL,
    @loan_type VARCHAR(20) = NULL,
    @status VARCHAR(20) = NULL,
    @approved_by NCHAR(10) = NULL,
    @from_date DATE = NULL,
    @to_date DATE = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Must have at least one search criteria in @customer_id, @status or @approved_by
        IF @customer_id IS NULL AND @status IS NULL AND @approved_by IS NULL 
            THROW 96000 , 'At least one search criteria must be provided.', 1;
        
        -- Validate customer ID
        IF @customer_id IS NOT NULL AND dbo.fn_customer_validate_id(@customer_id) = 0
            THROW 96001 , 'Invalid customer ID.', 1;

        -- Validate loan type
        IF @loan_type IS NOT NULL AND dbo.fn_loan_validate_type(@loan_type) = 0
            THROW 96002 , 'Invalid loan type.', 1;

        -- Validate status
        IF @status IS NOT NULL AND dbo.fn_loan_validate_status(@status) = 0
            THROW 96003 , 'Invalid loan status.', 1;

        -- Validate approved_by
        IF @approved_by IS NOT NULL AND dbo.fn_loan_validate_loan_officer(@approved_by) = 0
            THROW 96004 , 'Invalid employee ID.', 1;

        -- Validate date range
        IF @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date > @to_date
            THROW 96005 , 'Invalid date range. From date must be less than or equal to To date.', 1;

        -- Return the loans matching the search criteria
        SELECT *
        FROM vw_LoanDetails
        WHERE (@customer_id IS NULL OR customer_id = @customer_id)
            AND (@loan_type IS NULL OR loan_type = @loan_type)
            AND (@status IS NULL OR status = @status)
            AND (@approved_by IS NULL OR approved_by = @approved_by)
            AND (@from_date IS NULL OR start_date >= @from_date)
            AND (@to_date IS NULL OR start_date <= @to_date)
        ORDER BY start_date DESC , loan_id DESC;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END