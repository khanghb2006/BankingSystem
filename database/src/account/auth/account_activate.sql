/*
    Authentication: Activate Account
    Description : This stored procedure activates a Pending account after its
        'Register' OTP has been verified.
*/

USE BankingSystem;
GO

/*
    Input:
        @account_id : The account ID of the user.

    Output:
        + account_id
        + username
        + email
        + phone_number
        + role
        + status
        + message

    Flow:
        1. User registers via sp_account_register (account created with 'Pending' status)
        2. sp_otp_generate_otpcode is called to generate OTP and send to user
        3. User submits OTP
        4. sp_otp_verify is called to verify OTP
        5. sp_account_activate activates the account
        6. Used OTP is marked as verified
*/
CREATE OR ALTER PROCEDURE sp_account_activate
    @account_id BIGINT
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
            IF dbo.fn_otp_validate_verify(@account_id, 'Register') = 0
                THROW 10001, 'OTP is not verified.', 1;

            -- Activate account
            UPDATE Account
            SET
                status = 'Active',
                updated_at = GETDATE()
            WHERE account_id = @account_id
                AND status = 'Pending';

            IF @@ROWCOUNT = 0
                THROW 10002, 'Failed to activate account.', 1;

            -- Delete used OTP
            DELETE FROM OTP
            WHERE account_id = @account_id
                AND purpose = 'Register'
                AND verified = 1;

        COMMIT TRANSACTION;

        -- Return the activated account
        SELECT *,
            'Account activated successfully.' AS message
        FROM vw_Account
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
