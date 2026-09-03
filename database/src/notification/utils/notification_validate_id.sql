USE BankingSystem
GO

/** 
    Function : fn_notification_validate_id
    Decription : This function is used to validate the notification ID.

    Input:
        + @notification_id BIGINT : The ID of the notification to be validated.

    Output:
        + 1 if the notification ID exists in the Notification table, otherwise 0.
*/
CREATE OR ALTER FUNCTION fn_notification_validate_id
    (@notification_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Notification
        WHERE notification_id = @notification_id
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END
GO