/*
    Bank Account Views
    Author : Huynh Bao Khang
    Description : Views related to bank accounts
*/

USE BankingSystem;
Go

/* 
------------------------------------------------------
    View: vw_BankAccountDetails
    Description : Public bank account information (masked sensitive data)
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_BankAccountDetails
AS
    SELECT 
        BA.bank_account_id,
        BA.bank_account_number,
        BA.customer_id,
        C.full_name,
        BA.account_type,
        BA.balance,
        B.branch_id,
        B.branch_name,
        BA.opened_at,
        BA.status
    from BankingAccount BA
    JOIN Customer C ON BA.customer_id = C.customer_id
    JOIN Branch B ON C.branch_id = B.branch_id;
GO

/* 
------------------------------------------------------
    View: vw_BankAccountSummary
    Description : Lightweight bank account information for listing and searching
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_BankAccountSummary
AS
    SELECT 
        BA.bank_account_id,
        BA.bank_account_number,
        BA.customer_id,
        C.full_name,
        BA.account_type,
        BA.status
    FROM BankingAccount BA
    JOIN Customer C ON BA.customer_id = C.customer_id
    JOIN Branch B ON C.branch_id = B.branch_id;
GO