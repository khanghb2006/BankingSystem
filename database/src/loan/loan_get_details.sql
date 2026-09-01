USE BankingSystem
GO

/**
    Procedure : sp_loan_get_details
    Description : This procedure is used to retrieve the details of a specific loan.

    Input:
        + @customer_id NCHAR(10) : The ID of the customer who owns the loan.
        + @loan_id BIGINT : The ID of the loan for which details are to be retrieved.
    
    Output:
        + vw_LoanDetails : A view that provides comprehensive details of the specified loan, including customer information, loan amount, duration, interest rate, monthly payment, remaining balance, and status.
*/
CREATE OR ALTER PROCEDURE sp_loan_get_details
    @customer_id NCHAR(10),
    @loan_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        -- Validate loan ID
        IF dbo.fn_loan_validate_id(@loan_id) = 0
            THROW 93000 , 'Invalid loan ID.', 1;

        -- Validate the customer owns this loan
        IF dbo.fn_loan_validate_owner(@loan_id, @customer_id) = 0
            THROW 93001 , 'This loan does not belong to the given customer.', 1;

        -- Retrieve loan details
        SELECT *
        FROM vw_LoanDetails
        WHERE loan_id = @loan_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH

END