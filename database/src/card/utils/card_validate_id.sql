USE BankingSystem;
GO

/**
    Function: fn_card_validate_id
    Description: This function checks if a card ID exists in the Card table.

    Input:
        + @card_id : Card ID to validate

    Output:
        + 1 if the card ID exists, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_card_validate_id
    (@card_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Card
        WHERE card_id = @card_id
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END