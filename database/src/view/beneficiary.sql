USE BankingSystem;
GO

/*
    View: vw_BeneficiaryDetails
    Description : Saved beneficiary information, including
        the real account holder name so the customer can
        double-check it against the nickname they saved.
*/
CREATE OR ALTER VIEW vw_BeneficiaryDetails
AS
    SELECT
        B.beneficiary_id,
        B.customer_id,

        -- Beneficiary info as saved by the customer
        B.beneficiary_name,
        B.bank_name,

        -- Destination account (for verification/display)
        B.bank_account_id,
        dbo.fn_mask_bank_account_number(BA.bank_account_number) 
            AS masked_bank_account_number,
        BA.status AS bank_account_status,
        C.full_name AS account_holder_name,

        B.created_at
    FROM Beneficiary B
    LEFT JOIN BankingAccount BA 
        ON B.bank_account_id = BA.bank_account_id
    LEFT JOIN Customer C 
        ON BA.customer_id = C.customer_id;
GO