USE BankingSystem
GO

/** 
    Procedure : sp_bank_transaction_get_details
    Decription : This procedure is used to get the details of a bank transaction based on the transaction ID.

    Input : 
        + @transaction_id BIGINT - The ID of the transaction to retrieve details for.

    Output :
        + vw_TransactionDetails
*/
CREATE OR ALTER PROCEDURE sp_bank_transaction_get_details
    @transaction_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate transaction ID  
        IF dbo.fn_bank_transaction_validate_id(@transaction_id) = 0
            THROW 220000, 'Invalid transaction ID.', 1;

        -- Retrieve transaction details
        SELECT *
        FROM vw_TransactionDetails
        WHERE transaction_id = @transaction_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END