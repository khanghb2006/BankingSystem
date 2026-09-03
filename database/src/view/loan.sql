USE BankingSystem;
GO

/**
    View : vw_LoanDetails
    Description : View to display detailed information about loans, including customer and loan type details.
*/
CREATE OR ALTER VIEW vw_LoanDetails
AS
    SELECT 
        -- Loan information
        L.loan_id,
        L.loan_type,
        L.amount,
        L.interest_rate,
        L.remaining_balance,
        L.duration_months,
        L.start_date,
        L.end_date,
        L.monthly_payment,
        L.status,
        L.approved_by,

        -- Customer information
        C.customer_id,
        C.full_name,
        dbo.fn_mask_email(A.email) AS masked_customer_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_customer_phone,
        C.address
    FROM Loan L
    JOIN Customer C ON L.customer_id = C.customer_id
    JOIN Account A ON C.account_id = A.account_id;
GO