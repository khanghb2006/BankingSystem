USE BankingSystem;
GO

/**
    View : vw_SavingAccountDetails
    Description : Detailed information about term-deposit saving accounts,
        including the source banking account and customer, plus the projected
        simple-interest values for the full term.

    Note :
        + projected_interest = deposit_amount * interest_rate / 100 * term_months / 12
        + maturity_amount    = deposit_amount + projected_interest
*/
CREATE OR ALTER VIEW vw_SavingAccountDetails
AS
    SELECT
        -- Saving account information
        SA.saving_id,
        SA.source_bank_account_id,
        dbo.fn_mask_bank_account_number(BA.bank_account_number)
            AS masked_source_account_number,
        SA.deposit_amount,
        SA.interest_rate,
        SA.term_months,
        SA.start_date,
        SA.maturity_date,
        SA.status,

        -- Projected values (simple interest over the full term)
        CAST(SA.deposit_amount * SA.interest_rate / 100.0 * SA.term_months / 12.0
            AS DECIMAL(18, 2)) AS projected_interest,
        CAST(SA.deposit_amount
            + SA.deposit_amount * SA.interest_rate / 100.0 * SA.term_months / 12.0
            AS DECIMAL(18, 2)) AS maturity_amount,

        -- Customer information
        C.customer_id,
        C.full_name,
        dbo.fn_mask_email(A.email) AS masked_customer_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_customer_phone
    FROM SavingAccount SA
    JOIN BankingAccount BA ON SA.source_bank_account_id = BA.bank_account_id
    JOIN Customer C ON BA.customer_id = C.customer_id
    JOIN Account A ON C.account_id = A.account_id;
GO
