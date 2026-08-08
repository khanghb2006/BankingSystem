USE BankingSystem
GO

/*
    Function : fn_username_to_id
    Description: This function is used to convert a username to its corresponding user ID.
*/
CREATE OR ALTER FUNCTION fn_username_to_id
    (@username VARCHAR(50))
RETURNS INT
AS
BEGIN
    DECLARE @account_id BIGINT;
    
    SELECT @account_id = account_id
    FROM Account
    WHERE username = @username;

    RETURN @account_id;
END
