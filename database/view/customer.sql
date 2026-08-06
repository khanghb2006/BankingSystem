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

        CONCAT (
            LEFT(A.username , 3) , 
            REPLICATE('*', LEN(A.username) - 3)
        ) AS masked_username,

        CONCAT (
            LEFT(A.email , 4) , 
            REPLICATE('*', CHARINDEX('*', A.email) - 4)
        ) AS masked_email,

        CONCAT (
            REPLICATE('*', LEN(A.phone_number) - 3),
            RIGHT(A.phone_number , 3)
        ) AS masked_phone_number,

        C.full_name,
        C.dob,
        C.gender,
        CONCAT (
            REPLICATE('*', LEN(C.citizen_id) - 4),
            RIGHT(C.citizen_id , 4)
        ) AS masked_citizen_id,
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
        CONCAT (
            LEFT(A.email , 4) , 
            REPLICATE('*', CHARINDEX('*', A.email) - 4)
        ) AS masked_email,

        CONCAT (
            REPLICATE('*', LEN(A.phone_number) - 3),
            RIGHT(A.phone_number , 3)
        ) AS masked_phone_number,
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