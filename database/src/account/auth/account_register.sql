/* 
    Authentication - Register
    Description: This stored procedure is used to register a new user in the system.
*/

USE BankingSystem;
GO

/*
    Parameters:
        @username : The username of the new user.
        @email : The email address of the new user.
        @phone_number : The phone number of the new user.
        @password : The password of the new user (hashed).

    Returns:
        + account_id
        + username
        + email
        + phone_number
        + role 
        + status
        + message
    
    Note : 
        + Password should be hashed before calling this stored procedure.
        + Public registeration can only create Customer accounts
        + New accounts are created with 'Pending' status
        + The account can only be used after OTP verification
*/
CREATE OR ALTER PROCEDURE sp_account_register
    @username VARCHAR(50),
    @email NVARCHAR(100),
    @phone_number VARCHAR(20),
    @password VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate username
            IF dbo.fn_account_validate_username(@username) = 1
                THROW 20000, 'Username already exists.', 1;
            
            -- Validate email
            IF dbo.fn_account_validate_email(@email) = 1
                THROW 20001, 'Email already exists.', 1;
            
            -- Validate phone number
            IF dbo.fn_account_validate_phone_number(@phone_number) = 1
                THROW 20002, 'Phone number already exists.', 1;

            -- Create a new account
            INSERT INTO Account
                (username, email, phone_number, password_hash, 
                    role, created_at, updated_at, status)
            VALUES
                (@username, @email, @phone_number, @password, 
                    'Customer', GETDATE(), NULL, 'Pending')

            IF @@ROWCOUNT = 0
                THROW 20003, 'Failed to create account.', 1;
            
            -- Return created account information
            SELECT *,
                'Registration successful. Please verify your account via OTP.' AS message
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
