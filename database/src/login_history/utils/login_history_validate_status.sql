USE BankingSystem;
GO

/** 
    Function : fn_login_history_validate_status
    Decription : This function is used to validate the status of a login history record.

    Input:
        + @login_status VARCHAR(20) : The status of the login history record to validate.

    Output:
        + 1 : If the login status is valid , otherwise 0.
*/
CREATE OR ALTER FUNCTION fn_login_history_validate_status
    (@login_status VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM LoginHistoryStatus
        WHERE status_name = @login_status
    )
        SET @is_valid = 1;

    RETURN @is_valid;

END
GO