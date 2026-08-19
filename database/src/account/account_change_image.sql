USE BankingSystem
GO

/**
    Function : sp_account_change_image
    Description : Allows a user to change the image associated with their account. Validates account ID and status, then updates the image URL in the Account table.

    Input:
        + @account_id : The account ID
        + @image_url : New image URL

    Output:
        + account_id : The updated account ID
        + image_url : The new image URL
        + updated_at : Timestamp of update
        + message : Status message (e.g., 'Image updated successfully')

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