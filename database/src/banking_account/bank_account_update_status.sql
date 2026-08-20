USE BankingSystem
GO

/**
    Procedure: sp_bank_account_update_status
    Description: Update the status of a bank account.
    
    Input:
        + @bank_account_id : The unique identifier of the bank account to update (required).
        + @new_status : The new status to set for the bank account (required).

    Output:
        + vw_BankAccountDetails
        + message

    Note :
        + The new status must be a valid status as defined in the system.
*/
CREATE OR ALTER PROCEDURE sp_bank_account_update_status
    @bank_account_id INT,
    @new_status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            -- Validate bank_account_id
            IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
                THROW 30013, 'Bank account does not exist.', 1;

            -- Validate new_status
            IF dbo.fn_bank_account_validate_status(@new_status) = 0
                THROW 30012, 'Invalid status.', 1;

            -- Update the status of the bank account
            UPDATE BankingAccount
            SET status = @new_status
            WHERE bank_account_id = @bank_account_id;

            IF @@ROWCOUNT = 0
                THROW 30014, 'Status update failed', 1;

        COMMIT TRANSACTION;
        -- Return message
        SELECT *,
            'Status updated successfully.' AS message
        FROM vw_BankAccountDetails
        WHERE bank_account_id = @bank_account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
