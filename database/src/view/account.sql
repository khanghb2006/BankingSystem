/*
====================================================
    Account Views
    Author : Huynh Bao Khang
    Description : Views related to bank accounts
====================================================
*/

use BankingSystem;
go

/* 
------------------------------------------------------
    View: vw_Account
    Description : Public account information (without password)
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_Account 
AS
    SELECT 
        account_id,
        username,
        email,
        phone_number,
        role,
        created_at,
        updated_at,
        status
    FROM Account;
GO
