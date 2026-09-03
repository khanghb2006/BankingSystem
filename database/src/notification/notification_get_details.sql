USE BankingSystem;
GO

/** 
    Procedure: sp_notification_get_details
    Description: This stored procedure is used to retrieve the details of a notification.

    Input : 
        + @notification_id BIGINT : The ID of the notification to retrieve.
    
    Output: 
        + vw_NotificationDetails
*/
CREATE OR ALTER PROCEDURE dbo.sp_notification_get_details
    @notification_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate notification id
        IF dbo.fn_notification_validate_id(@notification_id) = 0
            THROW 112000, 'Notification does not exist.', 1;

        -- Retrieve the notification details
        SELECT *
        FROM vw_NotificationDetails
        WHERE notification_id = @notification_id;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO