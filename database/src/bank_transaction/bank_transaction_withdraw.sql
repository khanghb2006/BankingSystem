USE BankingSystem
GO

/**
    Procedure: sp_bank_transaction_withdraw
    Description: Withdraw money from a bank account.

    Input:
        + @bank_account_id BIGINT
        + @amount DECIMAL(18, 2)
        + @description NVARCHAR(255) = NULL

    Output:
        + vw_TransactionDetails
        + message

    Note:
        + from_bank_account_id and to_bank_account_id are both set to
          @bank_account_id since withdrawals have no destination account in the system.
        + The balance check and deduction happen in a single UPDATE ... WHERE
          statement so concurrent withdrawals cannot overdraw the account.
*/
CREATE OR ALTER PROCEDURE sp_bank_transaction_withdraw
    @bank_account_id BIGINT,
    @amount DECIMAL(18, 2),
    @description NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate bank_account_id
            IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
                THROW 71000, 'Bank account does not exist.', 1;

            -- Validate amount
            IF @amount <= 0
                THROW 71001, 'Amount must be greater than 0.', 1;

            -- Debit the account only if there is enough available balance
            UPDATE BankingAccount
            SET
                balance = balance - @amount,
                available_balance = available_balance - @amount
            WHERE bank_account_id = @bank_account_id
                AND status = 'Active'
                AND available_balance >= @amount;

            IF @@ROWCOUNT = 0
                THROW 71002, 'Insufficient balance or account is not active.', 1;

            -- Record the transaction
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@bank_account_id, @bank_account_id, 'Withdrawal',
                    @amount, 0, @description, GETDATE(), 'Successful');

            DECLARE @transaction_id BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Withdrawal successful.' AS message
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
