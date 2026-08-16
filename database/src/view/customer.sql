/*
====================================================
    Customer Views
    Author : Huynh Bao Khang
    Description : Views related to customers
====================================================
*/

USE BankingSystem;
GO

/* 
------------------------------------------------------
    View: vw_CustomerDetails
    Description : Public customer information (masked sensitive data)
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_CustomerDetails
AS
    SELECT 
        C.customer_id,
        C.account_id,
        A.username,
        dbo.fn_mask_email(A.email) AS masked_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_phone_number,
        C.full_name,
        C.dob,
        C.gender,
        dbo.fn_mask_citizen_id(C.citizen_id) AS masked_citizen_id,
        C.address,
        C.branch_id,
        C.created_at,
        C.updated_at
    FROM Customer C  
    JOIN Account A ON C.account_id = A.account_id;
GO

/* 
------------------------------------------------------
    View: vw_CustomerSummary
    Description : Lightweight customer information for customer listing and searching
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_CustomerSummary
AS
    SELECT 
        C.customer_id,
        C.full_name,
        dbo.fn_mask_email(A.email) AS masked_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_phone_number,
        C.branch_id,
        C.created_at,
        A.status
    FROM Customer C
    JOIN Account A ON C.account_id = A.account_id;
GO

/*
------------------------------------------------------
    View: vw_CustomerStatistics
    Description : Customer statistics for reporting and analytics
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_CustomerStatistics
AS
    SELECT 
        C.customer_id,
        C.full_name,
        C.branch_id,

        COUNT(DISTINCT BA.bank_account_id) AS total_bank_accounts,
        COUNT(DISTINCT CD.card_id) AS total_cards,
        ISNULL(SUM(BA.balance), 0) AS total_balance
    FROM Customer C
    JOIN BankingAccount BA ON C.customer_id = BA.customer_id
    JOIN Card CD ON CD.bank_account_id = BA.bank_account_id
    GROUP BY C.customer_id, C.full_name, C.branch_id;
GO