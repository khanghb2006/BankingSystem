USE BankingSystem;
GO

/** 
    Procedure : sp_card_update_status
    Description : This procedure updates the status of a card.

    Input: 
        + @card_id BIGINT
        + @new_status VARCHAR(20)

    Output:
        + vw_CardDetails
        + message : Success or Failure message
*/
CREATE OR ALTER PROCEDURE sp_card_update_status
    @card_id BIGINT,
    @new_status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION
            -- Validate card id
            IF dbo.fn_card_validate_id(@card_id) = 0
                THROW 64000, 'Invalid card ID.', 1;

            -- Validate new status
            IF dbo.fn_card_validate_status(@new_status) = 0
                THROW 64001, 'Invalid card status.', 1;

            -- Update card status
            UPDATE Card
            SET status = @new_status
            WHERE card_id = @card_id;

            IF @@ROWCOUNT = 0
                THROW 64002, 'Failed to update card status.', 1;

        COMMIT TRANSACTION;

        -- Return updated card details
        SELECT *,
            'Card status updated successfully.' AS message
        FROM vw_CardDetails
        WHERE card_id = @card_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END
