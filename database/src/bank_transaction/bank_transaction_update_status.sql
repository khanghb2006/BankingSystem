USE BankingSystem
GO

/**
    Procedure: sp_bank_transaction_update_status
    Description: Update the status of a bank transaction.

    Input:
        + @transaction_id BIGINT
        + @new_status NVARCHAR(20)

    Output:
        + vw_TransactionDetails
        + message
*/
CREATE OR ALTER PROCEDURE sp_bank_transaction_update_status
    @transaction_id BIGINT,
    @new_status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate transaction_id
            IF dbo.fn_bank_transaction_validate_id(@transaction_id) = 0
                THROW 260000, 'Invalid transaction ID.', 1;

            -- Validate new_status
            IF dbo.fn_bank_transaction_validate_status(@new_status) = 0
                THROW 260010, 'Invalid status.', 1;

            -- Update transaction status
            UPDATE BankTransaction
            SET status = @new_status
            WHERE transaction_id = @transaction_id;

            IF @@ROWCOUNT = 0
                THROW 260020, 'Failed to update transaction status.', 1;

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Transaction status updated successfully.' AS message
        FROM vw_TransactionDetails
        WHERE transaction_id = @transaction_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
