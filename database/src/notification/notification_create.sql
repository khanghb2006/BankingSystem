USE BankingSystem;
GO

/** 
    Procedure: sp_notification_create
    Description: This stored procedure is used to create a new notification.

    Input : 
        + @account_id BIGINT : The ID of the account to which the notification belongs.
        + @title VARCHAR(20) : The title of the notification.
        + @message NVARCHAR(255) : The message content of the notification.
    
    Output:
        + vw_NotificationDetails
        + result_message
*/

CREATE OR ALTER PROCEDURE dbo.sp_notification_create
    @account_id BIGINT,
    @title VARCHAR(20),
    @message NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 111000, 'Account does not exist.', 1;

            -- Validate title
            IF dbo.fn_notification_validate_type(@title) = 0
                THROW 111010, 'Invalid notification title.', 1;

            -- Validate message
            IF @message IS NULL OR LEN(@message) = 0
                THROW 111020, 'Notification message cannot be empty.', 1;

            -- Insert the new notification
            INSERT INTO Notification
                (account_id, title, message, is_read, created_at)
            VALUES
                (@account_id, @title, @message, 0, GETDATE());

            IF @@ROWCOUNT = 0
                THROW 111030, 'Failed to create notification.', 1;

        COMMIT TRANSACTION;

        -- Return message
        DECLARE @notification_id BIGINT = SCOPE_IDENTITY();

        SELECT *,
            'Notification created successfully.' AS result_message
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