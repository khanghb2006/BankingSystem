USE BankingSystem
GO

/**
    Function : fn_get_account_id_by_username
    Description : This function is used to convert a username to its corresponding user ID.

    Input:
        + @username : The username to look up

    Output:
        + account_id : The corresponding account ID, or NULL if not found
*/
CREATE OR ALTER FUNCTION fn_get_account_id_by_username
    (@username VARCHAR(50))
RETURNS BIGINT
AS
BEGIN
    DECLARE @account_id BIGINT;
    
    SELECT @account_id = account_id
    FROM Account
    WHERE username = @username;

    RETURN @account_id;
END
