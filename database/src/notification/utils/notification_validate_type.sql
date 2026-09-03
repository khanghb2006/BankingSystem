USE BankingSystem;
GO

/** 
    Function : fn_notification_validate_type
    Description : This function is used to validate the notification type.

    Input:
        + @notification_type VARCHAR(20) : The type of the notification to be validated.

    Output:
        + 1 if the notification type is valid, otherwise 0.
*/
CREATE OR ALTER FUNCTION fn_notification_validate_type
    (@notification_type VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM NotificationType
        WHERE type_name = @notification_type
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END
GO