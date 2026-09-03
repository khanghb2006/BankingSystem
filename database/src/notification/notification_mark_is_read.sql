USE BankingSystem;
GO

/**
    Procedure: sp_notification_mark_is_read
    Description: This stored procedure is used to mark a notification as read.

    Input :
        + @notification_id BIGINT : The ID of the notification to mark as read.
        + @account_id BIGINT : The ID of the account that owns the notification.

    Output:
        + vw_NotificationDetails
        + result_message
*/
CREATE OR ALTER PROCEDURE dbo.sp_notification_mark_is_read
    @notification_id BIGINT,
    @account_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate notification id
            IF dbo.fn_notification_validate_id(@notification_id) = 0
                THROW 113000, 'Notification does not exist.', 1;

            -- Validate ownership
            IF dbo.fn_notification_validate_owner(@notification_id, @account_id) = 0
                THROW 113010, 'This notification does not belong to the given account.', 1;

            -- Mark the notification as read
            UPDATE Notification
            SET is_read = 1
            WHERE notification_id = @notification_id;

            IF @@ROWCOUNT = 0
                THROW 113020, 'Failed to mark notification as read.', 1;

        COMMIT TRANSACTION;

        -- Return result
        SELECT *,
            'Notification marked as read successfully.' AS result_message
        FROM vw_NotificationDetails
        WHERE notification_id = @notification_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
