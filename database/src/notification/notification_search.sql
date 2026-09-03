USE BankingSystem;
GO

/** 
    Procedure: sp_notification_search
    Description: This stored procedure is used to search for notifications based on various criteria.

    Input : 
        + @account_id BIGINT : The ID of the account to which the notifications belong.
        + @title VARCHAR(20) = NULL : The title of the notification (optional).
        + @is_read BIT = NULL : The read status of the notification (optional).
        + @start_date DATETIME = NULL : The start date for filtering notifications (optional).
        + @end_date DATETIME = NULL : The end date for filtering notifications (optional).
    
    Output: 
        + vw_NotificationDetails
*/
CREATE OR ALTER PROCEDURE sp_notification_search
    @account_id BIGINT,
    @title VARCHAR(20) = NULL,
    @is_read BIT = NULL,
    @start_date DATETIME = NULL,
    @end_date DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate account id
        IF dbo.fn_account_validate_id(@account_id) = 0
            THROW 11400, 'Account does not exist.', 1;

        -- Validate title if provided
        IF @title IS NOT NULL AND dbo.fn_notification_validate_type(@title) = 0
            THROW 11401, 'Invalid notification title.', 1;

        -- Validate date range if provided
        IF @start_date IS NOT NULL AND @end_date IS NOT NULL AND @start_date > @end_date
            THROW 11402, 'Start date cannot be later than end date.', 1;

        -- Search for notifications based on the provided criteria
        SELECT *
        FROM vw_NotificationDetails
        WHERE account_id = @account_id
            AND (@title IS NULL OR title = @title)
            AND (@is_read IS NULL OR is_read = @is_read)
            AND (@start_date IS NULL OR created_at >= @start_date)
            AND (@end_date IS NULL OR created_at <= @end_date)
        ORDER BY created_at DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO