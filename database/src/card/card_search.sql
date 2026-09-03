USE BankingSystem;
GO

/** 
    Procedure : sp_card_search
    Description : This procedure searches for cards based on the provided search criteria.

    Input: 
        + @bank_account_id BIGINT
        + @card_type VARCHAR(20) (optional)
        + @status VARCHAR(20) (optional)

    Output:
        + vw_CardDetails
*/
CREATE OR ALTER PROCEDURE dbo.sp_card_search
    @bank_account_id BIGINT,
    @card_type VARCHAR(20) = NULL,
    @status VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate bank account id
        IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
            THROW 63000, 'Invalid bank account ID.', 1;

        -- Validate card type if provided
        IF @card_type IS NOT NULL AND dbo.fn_card_validate_type(@card_type) = 0
            THROW 63001, 'Invalid card type.', 1;
        
        -- Validate status if provided
        IF @status IS NOT NULL AND dbo.fn_card_validate_status(@status) = 0
            THROW 63002, 'Invalid card status.', 1;

        -- Retrieve card details based on the provided criteria
        SELECT *
        FROM vw_CardDetails
        WHERE bank_account_id = @bank_account_id
            AND (@card_type IS NULL OR card_type = @card_type)
            AND (@status IS NULL OR status = @status);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END