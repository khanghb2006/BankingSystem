USE BankingSystem
GO

/**
    Procedure: sp_bank_transaction_transfer
    Description: Transfer money from one bank account to another.

    Input:
        + @from_bank_account_id BIGINT
        + @to_bank_account_id BIGINT
        + @amount DECIMAL(18, 2)
        + @fee DECIMAL(18, 2) = 0
        + @description NVARCHAR(255) = NULL

    Output:
        + vw_TransactionDetails
        + message

    Note:
        + @amount + @fee is deducted from the source account; @amount is
          credited to the destination account.
        + The balance check and deduction happen in a single UPDATE ... WHERE
          statement so concurrent transfers cannot overdraw the source account.
*/
CREATE OR ALTER PROCEDURE sp_bank_transaction_transfer
    @from_bank_account_id BIGINT,
    @to_bank_account_id BIGINT,
    @amount DECIMAL(18, 2),
    @fee DECIMAL(18, 2) = 0,
    @description NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate from_bank_account_id
            IF dbo.fn_bank_account_validate_id(@from_bank_account_id) = 0
                THROW 72000, 'Source bank account does not exist.', 1;

            -- Validate to_bank_account_id
            IF dbo.fn_bank_account_validate_id(@to_bank_account_id) = 0
                THROW 72001, 'Destination bank account does not exist.', 1;

            -- Validate accounts are different
            IF @from_bank_account_id = @to_bank_account_id
                THROW 72002, 'Source and destination accounts must be different.', 1;

            -- Validate amount
            IF @amount <= 0
                THROW 72003, 'Amount must be greater than 0.', 1;

            -- Debit the source account only if there is enough available balance
            UPDATE BankingAccount
            SET
                balance = balance - (@amount + @fee),
                available_balance = available_balance - (@amount + @fee)
            WHERE bank_account_id = @from_bank_account_id
                AND status = 'Active'
                AND available_balance >= (@amount + @fee);

            IF @@ROWCOUNT = 0
                THROW 72004, 'Insufficient balance or source account is not active.', 1;

            -- Credit the destination account
            UPDATE BankingAccount
            SET
                balance = balance + @amount,
                available_balance = available_balance + @amount
            WHERE bank_account_id = @to_bank_account_id
                AND status = 'Active';

            IF @@ROWCOUNT = 0
                THROW 72005, 'Destination account is not active.', 1;

            -- Record the transaction
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@from_bank_account_id, @to_bank_account_id, 'Transfer',
                    @amount, @fee, @description, GETDATE(), 'Successful');

            DECLARE @transaction_id BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Transfer successful.' AS message
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
