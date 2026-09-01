USE BankingSystem;
GO

/**
    Procedure : sp_loan_apply
    Description : This procedure is used to apply for a loan.

    Input:
        + @customer_id NCHAR(10) : The ID of the customer applying for the loan.
        + @loan_amount DECIMAL(18, 2) : The amount of the loan
        + @loan_type VARCHAR(20) : The type of the loan (e.g., Personal, Home, Auto).
        + @duration_months INT : The duration of the loan in months.
        + @annual_interest_rate DECIMAL(18, 2) : The annual interest rate for the loan.
    
    Output:
        + vw_LoanDetails : A view that provides details of the loan application, including the calculated monthly payment and the status of the application.
        + message

    Note:
        + monthly_payment is calculated using the formula:
            r = annual_interest_rate / 12 / 100
            M = P * r * (1 + r)^n / ((1 + r)^n - 1)
            where:
                M = monthly payment
                P = loan amount
                r = monthly interest rate
                n = number of payments (duration in months)
        + remaining_balance is initially set to the loan amount and will be updated as payments are made.
        + start_date is set to the current date, and end_date is calculated based on the duration of the loan.
        + status is initially set to 'Pending' and will be updated based on the approval process.
*/

CREATE OR ALTER PROCEDURE sp_loan_apply
    @customer_id NCHAR(10),
    @loan_type VARCHAR(20),
    @loan_amount DECIMAL(18, 2),
    @duration_months INT,
    @annual_interest_rate DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;
            -- Validate customer ID
            IF dbo.fn_customer_validate_id(@customer_id) = 0
                THROW 91000 , 'Invalid customer ID.', 1;
            
            -- Validate loan type
            IF dbo.fn_loan_validate_type(@loan_type) = 0
                THROW 91001 , 'Invalid loan type.', 1;

            -- Validate loan amount
            IF @loan_amount <= 0 OR @loan_amount IS NULL
                THROW 91002 , 'Loan amount must be greater than zero.', 1;
            
            -- Validate duration
            IF @duration_months <= 0 OR @duration_months IS NULL
                THROW 91003 , 'Duration must be greater than zero.', 1;

            -- Validate interest rate
            IF @annual_interest_rate <= 0 OR @annual_interest_rate IS NULL
                THROW 91004 , 'Interest rate must be greater than zero.', 1;
        
            -- Customer cannot have more than 1 pending loan application
            IF dbo.fn_loan_validate_pending_apply(@customer_id) = 1
                THROW 91005 , 'Customer already has a pending loan application.', 1;

            -- Calculate monthly payment
            DECLARE @start_date DATE = CAST(GETDATE() AS DATE);
            DECLARE @end_date DATE = DATEADD(MONTH, @duration_months, @start_date);

            DECLARE @r FLOAT = @annual_interest_rate / 12.0 / 100.0;
            DECLARE @pow FLOAT;
            DECLARE @monthly_payment DECIMAL(18, 2);

            IF @r = 0
                SET @monthly_payment = 
                    CAST(@loan_amount / @duration_months AS DECIMAL(18, 2));
            ELSE
            BEGIN
                SET @pow = POWER(1.0 + @r , @duration_months);
                SET @monthly_payment = 
                    CAST(@loan_amount * @r * @pow / (@pow - 1.0) AS DECIMAL(18, 2));
            END

            -- Create loan application (Pending status)
            INSERT INTO Loan
                (customer_id, loan_type, amount, interest_rate, remaining_balance, duration_months, 
                    start_date, end_date, monthly_payment, approved_by, status)
            VALUES
                (@customer_id, @loan_type, @loan_amount, @annual_interest_rate, @loan_amount, 
                    @duration_months, @start_date, @end_date, @monthly_payment, NULL, 'Pending');
            
            IF @@ROWCOUNT = 0
                THROW 91006 , 'Failed to create loan application.', 1;
        COMMIT TRANSACTION;
        -- Return message
        DECLARE @loan_id BIGINT = SCOPE_IDENTITY();

        SELECT *,
            'Loan application submitted successfully.' AS message
        FROM vw_LoanDetails
        WHERE loan_id = @loan_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END