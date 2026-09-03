USE BankingSystem;
GO

/**
    Procedure : sp_saving_account_open
    Description : Open a term-deposit saving account funded from an existing
        banking account.

    Input:
        + @customer_id NCHAR(10) : The customer opening the deposit.
        + @source_bank_account_id BIGINT : The banking account the money comes from.
        + @deposit_amount DECIMAL(18, 2) : The principal to lock in.
        + @term_months INT : The deposit term in months.
        + @interest_rate DECIMAL(18, 2) : The annual interest rate (percent) for the term.

    Output:
        + vw_SavingAccountDetails
        + message

    Note:
        + The principal is debited from the source account in the same UPDATE that
          checks it is Active and has enough available balance, so concurrent
          withdrawals cannot overdraw it.
        + start_date is today, maturity_date = start_date + @term_months months.
        + status starts as 'Active'.
*/
CREATE OR ALTER PROCEDURE dbo.sp_saving_account_open
    @customer_id NCHAR(10),
    @source_bank_account_id BIGINT,
    @deposit_amount DECIMAL(18, 2),
    @term_months INT,
    @interest_rate DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate customer ID
            IF dbo.fn_customer_validate_id(@customer_id) = 0
                THROW 350000, 'Invalid customer ID.', 1;

            -- Validate source bank account ID
            IF dbo.fn_bank_account_validate_id(@source_bank_account_id) = 0
                THROW 350010, 'Invalid bank account ID.', 1;

            -- Source account must belong to the customer
            IF dbo.fn_bank_account_validate_owner(@source_bank_account_id, @customer_id) = 0
                THROW 350020, 'Source account does not belong to the customer.', 1;

            -- Validate deposit amount
            IF @deposit_amount IS NULL OR @deposit_amount <= 0
                THROW 350030, 'Deposit amount must be greater than zero.', 1;

            -- Validate term
            IF @term_months IS NULL OR @term_months <= 0
                THROW 350040, 'Term must be greater than zero.', 1;

            -- Validate interest rate
            IF @interest_rate IS NULL OR @interest_rate < 0
                THROW 350050, 'Interest rate cannot be negative.', 1;

            -- Debit the source account (atomic; enforces Active + sufficient funds)
            UPDATE BankingAccount
            SET
                balance = balance - @deposit_amount,
                available_balance = available_balance - @deposit_amount
            WHERE bank_account_id = @source_bank_account_id
                AND status = 'Active'
                AND available_balance >= @deposit_amount;

            IF @@ROWCOUNT = 0
                THROW 350060, 'Insufficient balance or source account is not active.', 1;

            -- Create the deposit
            DECLARE @start_date DATE = CAST(GETDATE() AS DATE);

            INSERT INTO SavingAccount
                (source_bank_account_id, deposit_amount, interest_rate, term_months,
                    start_date, maturity_date, status)
            VALUES
                (@source_bank_account_id, @deposit_amount, @interest_rate, @term_months,
                    @start_date, DATEADD(MONTH, @term_months, @start_date), 'Active');

            IF @@ROWCOUNT = 0
                THROW 350070, 'Failed to open saving account.', 1;

            DECLARE @saving_id BIGINT = SCOPE_IDENTITY();

            -- Record the money moving into the deposit
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@source_bank_account_id, @source_bank_account_id, 'SavingDeposit',
                    @deposit_amount, 0,
                    N'Open saving account #' + CAST(@saving_id AS NVARCHAR(20)),
                    GETDATE(), 'Successful');

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Saving account opened successfully.' AS message
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
