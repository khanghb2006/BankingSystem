USE BankingSystem;
GO

/*
    Function: fn_mask_email
    Description: Masks an email address by preserving exactly the first 4 characters and replacing the remaining characters with asterisks (*).

    Example: johndoe@example.com -> johd*************

    Input: VARCHAR(255) email address
    Output: VARCHAR(255) masked email address
*/
CREATE OR ALTER FUNCTION dbo.fn_mask_email
    (@email VARCHAR(255))
RETURNS VARCHAR(255)
AS
BEGIN
    IF @email IS NULL
        RETURN NULL;

    IF LEN(@email) <= 4
        RETURN @email;

    DECLARE @mask_length INT = LEN(@email) - 4;

    RETURN LEFT(@email, 4) + REPLICATE('*', @mask_length);
END;
GO