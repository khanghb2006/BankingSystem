/*
====================================================
    Card Views
    Author : Huynh Bao Khang
    Description : Views related to bank cards
====================================================
*/

USE BankingSystem;
GO

/*
------------------------------------------------------
    View: vw_CardDetails
    Description : Public card information (masked sensitive data)
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_CardDetails
AS
    SELECT 
        C.card_id,
        C.card_number,
        C.bank_account_id,
        BA.customer_id,
        dbo.fn_mask_email(A.email) AS masked_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_phone,
        dbo.fn_mask_citizen_id(CS.citizen_id) AS masked_citizen_id,
        dbo.fn_mask_bank_account_number(BA.bank_account_number) AS masked_bank_account_number,
        C.card_type,
        C.expired_at,
        C.status
    FROM Card C
    JOIN BankingAccount BA ON C.bank_account_id = BA.bank_account_id
    JOIN Customer CS ON BA.customer_id = CS.customer_id
    JOIN Account A ON CS.account_id = A.account_id;