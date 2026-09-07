USE BankingSystem;
GO

/**
    Procedure: sp_card_get_details
    Description: This procedure retrieves the details of a card based on the provided card number.

    Input:
        + @card_number VARCHAR(16) : The card number for which details are to be retrieved.
    
    Output:
        + vw_CardDetails : A view containing the details of the card.
*/
CREATE OR ALTER PROCEDURE dbo.sp_card_get_details
    @card_number VARCHAR(20)
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

            -- Validate card number
            IF dbo.fn_card_validate_number(@card_number) = 0
                THROW 62000, 'Invalid card number.', 1;

            -- Retrieve card details (vw_CardDetails khong con cot card_number tho,
            -- doi chieu card_id qua bang Card)
            SELECT *
            FROM vw_CardDetails
            WHERE card_id = (SELECT card_id FROM Card WHERE card_number = @card_number);

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH

END
