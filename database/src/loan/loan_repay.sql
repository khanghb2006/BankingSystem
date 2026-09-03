USE BankingSystem;
GO

/**
    Procedure : sp_loan_repay
    Description : This procedure is used to process a loan repayment transaction.

    Input:
        + @customer_id NCHAR(10) : The ID of the customer who owns the loan.
        + @loan_id BIGINT : The ID of the loan for which repayment is to be made.
        + @bank_account_id BIGINT : The ID of the bank account from which the repayment amount will be deducted.
        + amount DECIMAL(18, 2) : The amount to be repaid.
        + description NVARCHAR(255) : A description or note for the repayment transaction. (optional)
    
    Output:
        + vw_LoanDetails : A view that provides updated details of the loan after the repayment transaction, including the remaining balance and status.
        + message

    Note:
        + remaining_balance = remaining_balance - amount
        + if amount >= remaining_balance, then status = 'Closed'
*/
CREATE OR ALTER PROCEDURE dbo.sp_loan_repay
    @customer_id NCHAR(10),
    @loan_id BIGINT,
    @bank_account_id BIGINT,
    @amount DECIMAL(18, 2),
    @description NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;
           -- Validate loan ID
            IF dbo.fn_loan_validate_id(@loan_id) = 0
                THROW 94000 , 'Invalid loan ID.', 1;

            -- Validate the customer owns this loan
            IF dbo.fn_loan_validate_owner(@loan_id, @customer_id) = 0
                THROW 94007 , 'This loan does not belong to the given customer.', 1;

            -- Validate bank account ID
            IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
                THROW 94001 , 'Invalid bank account ID.', 1;

            -- Validate repayment amount
            IF @amount <= 0 OR @amount IS NULL
                THROW 94002 , 'Repayment amount must be greater than zero.', 1;

            -- Get Loan information
            DECLARE @remaining_balance DECIMAL(18, 2);
            DECLARE @loan_status VARCHAR(20);

            SELECT
                @remaining_balance = remaining_balance,
                @loan_status = status
            FROM Loan
            WHERE loan_id = @loan_id;

            -- Just repay for loans that are disbursed and not fully repaid
            IF @loan_status <> 'Disbursed'
                THROW 94003 , 'Loan is not in a state that allows repayment.', 1;

            -- Validate bank account belongs to the customer
            IF dbo.fn_bank_account_validate_owner(@bank_account_id, @customer_id) = 0
                THROW 94004 , 'Bank account does not belong to the loan owner.', 1;

            DECLARE @payment DECIMAL(18, 2) = 
                IIF(@amount > @remaining_balance, @remaining_balance, @amount);
            
            -- Update bank account balance
            UPDATE BankingAccount
            SET
                balance = balance - @payment,
                available_balance = available_balance - @payment
            WHERE bank_account_id = @bank_account_id
                AND status = 'Active'
                AND available_balance >= @payment;

            IF @@ROWCOUNT = 0
                THROW 94005 , 'Insufficient funds in the bank account.', 1;

            -- Update loan remaining balance
            UPDATE Loan
            SET
                remaining_balance = remaining_balance - @payment,
                status = IIF(remaining_balance - @payment <= 0, 'Closed', 'Disbursed')
            WHERE loan_id = @loan_id
                AND status = 'Disbursed'
                AND remaining_balance >= @payment;

            IF @@ROWCOUNT = 0
                THROW 94006 , 'Repayment amount exceeds remaining balance.', 1;

            -- Record transaction
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@bank_account_id, @bank_account_id, 'LoanRepayment', @payment, 0,
                    COALESCE(@description,
                        N'Repayment for loan #' + CAST(@loan_id AS NVARCHAR(20))),
                    GETDATE(), 'Successful');

        COMMIT TRANSACTION;
        -- Return message
        SELECT *,
            CASE
                WHEN status <> 'Closed'
                    THEN 'Repayment successful.'
                ELSE 'Loan is fully repaid. No remaining balance.'
            END AS message
        FROM vw_LoanDetails
        WHERE loan_id = @loan_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END
