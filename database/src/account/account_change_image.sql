/* 
    Account - Change Image 
    Description: This stored procedure allows a user to change the image associated with their account. It validates the account ID, checks if the account is active, and updates the image URL in the Account table.
*/

USE BankingSystem;
GO

/*
    Parameters:
        + @account_id : Account ID
        + @image_url : New image URL

    Returns:
        + account_id
        + image_url
        + updated_at
        + message
    
    Note:
        + The actual image file is NOT stored in SQL SERVER
        + This procedure only updates the image URL in the Account table.
        + Image storage will be handled by the backend
*/
CREATE OR ALTER PROCEDURE ChangeAccountImage
    @account_id BIGINT,
    @image_url VARCHAR(2048)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account
            IF dbo.fn_account_validate_account_id(@account_id) = 0
                THROW 50030, 'Invalid account ID.', 1;
            
            -- Validate account status
            IF dbo.fn_account_validate_status(@account_id, 'Active') = 0
                THROW 50031, 'Account status must be Active.', 1;

            -- Update image URL in Account table
            UPDATE Account
            SET image_url = @image_url,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 50032, 'Failed to update account image.', 1;

        COMMIT TRANSACTION;

        -- Return the updated account information
        SELECT 
            account_id,
            image_url,
            updated_at,
            'Image updated successfully.' AS message
        FROM Account
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END