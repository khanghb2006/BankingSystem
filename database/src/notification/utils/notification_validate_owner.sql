USE BankingSystem;
GO

/** 
    Function : fn_notification_validate_owner
    Decription : This function is used to validate the owner of a notification.

    Input:
        + @notification_id BIGINT : The ID of the notification to be validated.
        + @account_id BIGINT : The ID of the account to be validated.
    
    Output:
        + 1 if the account_id is the owner of the notification, otherwise 0.
*/
CREATE OR ALTER FUNCTION fn_notification_validate_owner
    (@notification_id BIGINT, @account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_owner BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Notification
        WHERE notification_id = @notification_id 
            AND account_id = @account_id
    )
        SET @is_owner = 1;
    RETURN @is_owner;
END
GO