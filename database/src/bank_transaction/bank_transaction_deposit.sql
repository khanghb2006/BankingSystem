USE BankingSystem
GO

/**
    Procedure: sp_bank_transaction_deposit
    Description: Deposit money into a bank account.

    Input:
        + @bank_account_id BIGINT
        + @amount DECIMAL(18, 2)
        + @description NVARCHAR(255) = NULL

    Output:
        + vw_TransactionDetails
        + message

    Note:
        + from_bank_account_id and to_bank_account_id are both set to
          @bank_account_id since deposits have no source account in the system.
        + Only 'Active' accounts can receive deposits.
*/
CREATE OR ALTER PROCEDURE sp_bank_transaction_deposit
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
                THROW 70000, 'Bank account does not exist.', 1;

            -- Validate amount
            IF @amount <= 0
                THROW 70001, 'Amount must be greater than 0.', 1;

            -- Credit the account (atomic; also enforces the account is Active)
            UPDATE BankingAccount
            SET
                balance = balance + @amount,
                available_balance = available_balance + @amount
            WHERE bank_account_id = @bank_account_id
                AND status = 'Active';

            IF @@ROWCOUNT = 0
                THROW 70002, 'Account is not active.', 1;

            -- Record the transaction
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@bank_account_id, @bank_account_id, 'Deposit',
                    @amount, 0, @description, GETDATE(), 'Successful');

            DECLARE @transaction_id BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Deposit successful.' AS message
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
