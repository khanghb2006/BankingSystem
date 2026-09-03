USE BankingSystem
GO

/** 
    View : vw_LoginHistoryDetails
    Description : This view is used to retrieve the details of login history records.
*/
CREATE OR ALTER VIEW vw_LoginHistoryDetails
AS
    SELECT
        -- LoginHistory information
        L.login_id,
        L.login_time,
        L.ip_address,
        L.device,
        L.login_status,

        -- Account information
        A.account_id,
        A.username,
        dbo.fn_mask_email(A.email) AS masked_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_phone_number
    FROM LoginHistory L
    INNER JOIN Account A ON L.account_id = A.account_id;
GO