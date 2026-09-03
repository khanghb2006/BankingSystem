USE BankingSystem;
GO

/** 
    View : vw_NotificationDetails
    Description : View to display detailed information about notifications, 
        including account and customer details.
*/
CREATE OR ALTER VIEW vw_NotificationDetails
AS
    SELECT 
        -- Notification information
        N.notification_id,
        N.title,
        N.message,
        N.is_read,
        N.created_at,

        -- Account information
        A.account_id,
        dbo.fn_mask_email(A.email) AS masked_account_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_account_phone,
        A.status AS account_status
    FROM Notification N
    JOIN Account A ON N.account_id = A.account_id;
GO
