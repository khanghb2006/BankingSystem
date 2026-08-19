/* 
    Authentication - Login
    Description : Stored procedure for user login
*/

USE BankingSystem;
GO

/* 
    Parameters : 
        + @username : Username of the user
        + @password : Password of the user

    Returns : 
        + user type 
        + user/customer/employee id
        + email
        + role 
        + status
        + message

    Note : 
        + The password should be hashed by the backend before calling this procedure.
*/
CREATE OR ALTER PROCEDURE sp_account_login
    @username VARCHAR(50),
    @password VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE
                @account_id BIGINT,
                @status VARCHAR(20)

            -- Validate username
            IF dbo.fn_account_validate_username(@username) = 0
                THROW 10000, 'Username does not exist', 1;

            -- Get account_id for the username
            SET @account_id = dbo.fn_get_account_id_by_username(@username);

            -- Validate password
            IF dbo.fn_account_validate_password(@account_id, @password) = 0
                THROW 10001, 'Incorrect password', 1;

            -- Validate account is Active
            IF dbo.fn_account_validate_status(@account_id, 'Active') = 0
                THROW 10002, 'Account is not active', 1;

            -- Get account information
            SELECT *,
                'Login successful' AS message
            FROM vw_Account
            WHERE username = @username;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END