USE BankingSystem;
GO

/* 
    View: vw_Account
    Description : View to display account information, including role and status details.
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
