USE BankingSystem
GO

/**
    Procedure : sp_loan_disburse
    Description : This procedure is used to disburse a loan.

    Input:
        + @customer_id NCHAR(10) : The ID of the customer who owns the loan.
        + @loan_id BIGINT : The ID of the loan to be disbursed.
        + @bank_account_id BIGINT : The ID of the bank account to which the loan amount will be disbursed.
        + @description NVARCHAR(255) : A description of the loan disbursement.(optional)
    
    Output:
        + vw_LoanDetails : A view that provides details of the loan, including the updated status and disbursement date.
        + message

    Note:
        + The procedure checks if the loan is in 'Approved' status before disbursing it.
        + Upon successful disbursement, the loan status is updated to 'Disbursed', and the disbursement date is recorded.
*/
CREATE OR ALTER PROCEDURE sp_loan_disburse
    @customer_id NCHAR(10),
    @loan_id BIGINT,
    @bank_account_id BIGINT,
    @description NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;
            -- Validate loan ID
            IF dbo.fn_loan_validate_id(@loan_id) = 0
                THROW 92000 , 'Invalid loan ID.', 1;

            -- Validate the customer owns this loan
            IF dbo.fn_loan_validate_owner(@loan_id, @customer_id) = 0
                THROW 92006 , 'This loan does not belong to the given customer.', 1;

            -- Validate bank account ID
            IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
                THROW 92001 , 'Invalid bank account ID.', 1;

            -- Get loan information
            DECLARE @loan_amount DECIMAL(18, 2);
            DECLARE @duration_months INT;
            DECLARE @loan_status VARCHAR(20);

            SELECT
                @loan_amount = amount,
                @duration_months = duration_months,
                @loan_status = status
            FROM Loan
            WHERE loan_id = @loan_id;

            -- Just disburse if the loan is approved
            IF @loan_status <> 'Approved'
                THROW 92002 , 'Loan is not approved for disbursement.', 1;
            
            -- Validate that the bank account belongs to the customer
            IF dbo.fn_bank_account_validate_owner(@bank_account_id, @customer_id) = 0
                THROW 92003 , 'Bank account does not belong to the loan applicant.', 1;
            
            -- Update loan status to 'Disbursed'
            DECLARE @start_date DATE = CAST(GETDATE() AS DATE);

            UPDATE Loan
            SET
                status = 'Disbursed',
                start_date = @start_date,
                end_date = DATEADD(MONTH, @duration_months, @start_date),
                remaining_balance = @loan_amount
            WHERE loan_id = @loan_id
                AND status = 'Approved';

            IF @@ROWCOUNT = 0
                THROW 92004 , 'Loan already disbursed or no longer Approved', 1;

            -- Update bank account balance
            UPDATE BankingAccount
            SET
                balance = balance + @loan_amount,
                available_balance = available_balance + @loan_amount
            WHERE bank_account_id = @bank_account_id
                AND status = 'Active';

            IF @@ROWCOUNT = 0
                THROW 92005 , 'Destination account is not active.', 1;

            -- Record the transaction
            INSERT INTO BankTransaction
                (from_bank_account_id, to_bank_account_id, transaction_type,
                    amount, fee, description, created_at, status)
            VALUES
                (@bank_account_id , @bank_account_id, 'LoanDisbursement', @loan_amount, 0,
                    COALESCE(@description, N'Loan disbursement for loan ID: ' + CAST(@loan_id AS NVARCHAR(20))),
                    GETDATE(), 'Successful');

        COMMIT TRANSACTION;
        --  Return message
        SELECT *,
            'Loan disbursed successfully.' AS message
        FROM vw_LoanDetails
        WHERE loan_id = @loan_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END