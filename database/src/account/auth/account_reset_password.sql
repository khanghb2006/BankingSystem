/**
    Authentication: Reset Password
    Description : This stored procedure is used to reset the password for a user account.
*/

USE BankingSystem;
GO

/* 
    Input:
        @account_id : The account ID of the user.
        @new_password : The new password for the user (hashed).

    Output:
        + account_id
        + updated_at
        + message
    
    Flow:
        1. User requests a password reset
        2. sp_otp_generate_otpcode is called to generate a 'PasswordReset' OTP and send to user
        3. User submits the OTP and new password
        4. sp_otp_verify is called to verify the OTP
        5. Backend hashes the new password
        6. sp_account_reset_password checks the OTP is verified, updates the
           password, and deletes the used OTP
*/
CREATE OR ALTER PROCEDURE sp_account_reset_password
    @account_id BIGINT,
    @new_password VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 10000, 'Invalid account ID.', 1;

            -- Validate OTP is verified
            IF dbo.fn_otp_validate_verify(@account_id, 'PasswordReset') = 0
                THROW 10001, 'OTP is not verified.', 1;

            -- Update password
            UPDATE Account
            SET
                password_hash = @new_password,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 10002, 'Failed to reset password.', 1;

            -- Delete used OTP
            DELETE FROM OTP
            WHERE account_id = @account_id
                AND purpose = 'PasswordReset'
                AND verified = 1;

        COMMIT TRANSACTION;

        -- Return message
        SELECT 
            @account_id AS account_id,
            GETDATE() AS updated_at,
            'Password reset successful' AS message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH

END