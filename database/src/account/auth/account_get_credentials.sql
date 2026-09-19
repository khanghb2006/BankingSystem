USE BankingSystem;
GO

/**
    Procedure : sp_account_get_credentials
    Description : Internal-only lookup used by the backend to read an account's stored 
        password hash, so it can be verified with ASP.NET Core's PasswordHasher.
        
    PasswordHasher (PBKDF2 , salted -> cannot be compared with plain SQL so never return
        password_hash to an HTTP Client - this proc is only ever to called from AuthService

    Input:
        + @account_id : Lookup by account ID
        + @username : Lookup by username
        + Exactly one of the two should be supplied by the caller

    Output:
        + account_id
        + username
        + password_hash
        + status

    Note:
        + Returns 0 rows when not found.
*/
CREATE OR ALTER PROCEDURE sp_account_get_credentials
    @account_id BIGINT = NULL,
    @username VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        account_id,
        username,
        password_hash,
        status
    FROM Account
    WHERE (@account_id IS NOT NULL AND account_id = @account_id)
        OR (@username IS NOT NULL AND username = @username);
END
GO