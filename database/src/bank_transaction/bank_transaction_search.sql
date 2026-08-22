USE BankingSystem
GO

/**
    Procedure : sp_bank_transaction_search
    Description : This procedure is used to search for bank transactions based on various criteria such as transaction ID, account number, date range, and transaction type. It returns a list of matching transactions along with relevant details.

    Input :
        + @bank_account_id BIGINT
        + @transaction_type VARCHAR(20) (optional)
        + @status NVARCHAR(20) (optional)
        + @from_date DATE (optional)
        + @to_date DATE (optional)
*/
CREATE OR ALTER PROCEDURE sp_bank_transaction_search
    @bank_account_id BIGINT,
    @transaction_type VARCHAR(20) = NULL,
    @status NVARCHAR(20) = NULL,
    @from_date DATE = NULL,
    @to_date DATE = NULL
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate bank_account_id
        IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
            THROW 20001, 'Invalid bank account ID.', 1;
        
        -- Validate transaction_type if provided
        IF dbo.fn_bank_transaction_validate_type(@transaction_type) = 0 AND @transaction_type IS NOT NULL
            THROW 20002, 'Invalid transaction type.', 1;

        -- Validate status if provided
        IF dbo.fn_bank_transaction_validate_status(@status) = 0 AND @status IS NOT NULL
            THROW 20003, 'Invalid transaction status.', 1;

        -- Validate date range if provided
        IF @from_date IS NOT NULL AND @to_date IS NOT NULL 
            AND @from_date > @to_date
            THROW 20004, 'Invalid date range. From date cannot be later than to date.', 1;
            
        -- Retrieve transactions based on the provided criteria
        SELECT *
        FROM vw_TransactionSummary
        WHERE (from_bank_account_id = @bank_account_id
                OR to_bank_account_id = @bank_account_id)
            AND (@transaction_type IS NULL OR transaction_type = @transaction_type)
            AND (@status IS NULL OR status = @status)
            AND (@from_date IS NULL OR created_at >= @from_date)
            AND (@to_date IS NULL OR created_at <= @to_date)

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END