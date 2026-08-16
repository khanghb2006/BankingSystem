/* 
    Authentication: Change Password
    Description: This stored procedure allows a user to change their password. It validates the account ID, checks if the account is active, verifies the old password, and updates the password in the Authentication table.
*/

USE BankingSystem;
GO

/* 
    Parameters:
        + @account_id : Account ID
        + @old_password : Old password
        + @new_password : New password

    Returns:
        + account_id
        + updated_at
        + message
    
    Note:
        + Passwords are stored as hashed values in the Authentication table.
        + This procedure only updates the password in the Authentication table.
*/
CREATE OR ALTER PROCEDURE sp_account_change_password
    @account_id BIGINT,
    @old_password VARCHAR(255),
    @new_password VARCHAR(255)
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account ID
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 10000, 'Invalid account ID.', 1;
            
            -- Validate old password
            IF dbo.fn_account_validate_password(@account_id, @old_password) = 0
                THROW 10001, 'Old password is incorrect.', 1;
            
            -- new password should not be the same as the old password
            IF @old_password = @new_password
                THROW 10002, 'New password cannot be the same as the old password.', 1;
            
            -- Update password;
            UPDATE Account
            SET
                password_hash = @new_password,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 10003, 'Failed to update password.', 1;

        COMMIT TRANSACTION;

        -- Return success message
        SELECT 
            @account_id AS account_id,
            GETDATE() AS updated_at,
            'Password changed successfully.' AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END
