USE BankingSystem;
GO

/**
    Procedure : sp_saving_account_close
    Description : Close a saving account and return the money to the source
        banking account.

    Input:
        + @customer_id NCHAR(10) : The customer who owns the saving account.
        + @saving_id BIGINT : The saving account to close.
        + @description NVARCHAR(255) : Note for the payout transaction. (optional)

    Output:
        + vw_SavingAccountDetails
        + message

    Note:
        + Only 'Active' or 'Matured' saving accounts can be closed.
        + Interest is simple interest and is only paid once the term is reached:
              interest = deposit_amount * interest_rate / 100 * term_months / 12
          An early close returns the principal with zero interest.
        + payout = deposit_amount + interest is credited back to the source account.
*/
CREATE OR ALTER PROCEDURE dbo.sp_saving_account_close
    @customer_id NCHAR(10),
    @saving_id BIGINT,
    @description NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate saving account ID
            IF dbo.fn_saving_account_validate_id(@saving_id) = 0
                THROW 353000, 'Invalid saving account ID.', 1;

            -- Validate the customer owns this saving account
            IF dbo.fn_saving_account_validate_owner(@saving_id, @customer_id) = 0
                THROW 353010, 'This saving account does not belong to the given customer.', 1;

            -- Get saving account information
            DECLARE @status NVARCHAR(20);
            DECLARE @deposit_amount DECIMAL(18, 2);
            DECLARE @interest_rate DECIMAL(18, 2);
            DECLARE @term_months INT;
            DECLARE @maturity_date DATE;
            DECLARE @source_bank_account_id BIGINT;

            SELECT
                @status = status,
                @deposit_amount = deposit_amount,
                @interest_rate = interest_rate,
                @term_months = term_months,
                @maturity_date = maturity_date,
                @source_bank_account_id = source_bank_account_id
            FROM SavingAccount
            WHERE saving_id = @saving_id;

            -- Only open deposits can be closed
            IF @status NOT IN ('Active', 'Matured')
                THROW 353020, 'Saving account is already closed.', 1;

            -- Simple interest, only earned once the term is reached
            DECLARE @interest DECIMAL(18, 2) = 0;
            IF CAST(GETDATE() AS DATE) >= @maturity_date
                SET @interest = CAST(
                    @deposit_amount * @interest_rate / 100.0 * @term_months / 12.0
                    AS DECIMAL(18, 2));

            DECLARE @payout DECIMAL(18, 2) = @deposit_amount + @interest;

            -- Return principal + interest to the source account
            UPDATE BankingAccount
            SET
                balance = balance + @payout,
                available_balance = available_balance + @payout
            WHERE bank_account_id = @source_bank_account_id
                AND status = 'Active';

            IF @@ROWCOUNT = 0
                THROW 353030, 'Source account is not active.', 1;

            -- Close the deposit
            UPDATE SavingAccount
            SET status = 'Closed'
            WHERE saving_id = @saving_id
                AND status IN ('Active', 'Matured');

            IF @@ROWCOUNT = 0
                THROW 353040, 'Saving account is already closed.', 1;

            -- Record the payout
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@source_bank_account_id, @source_bank_account_id, 'SavingWithdrawal',
                    @payout, 0,
                    COALESCE(@description,
                        N'Close saving account #' + CAST(@saving_id AS NVARCHAR(20))
                        + N' (principal ' + CAST(@deposit_amount AS NVARCHAR(20))
                        + N' + interest ' + CAST(@interest AS NVARCHAR(20)) + N')'),
                    GETDATE(), 'Successful');

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            CASE
                WHEN @interest > 0
                    THEN 'Saving account closed at maturity. Principal and interest paid out.'
                ELSE 'Saving account closed early. Principal returned without interest.'
            END AS message
        FROM vw_SavingAccountDetails
        WHERE saving_id = @saving_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
