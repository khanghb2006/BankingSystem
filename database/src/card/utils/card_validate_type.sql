USE BankingSystem;
GO

/**
    Function: fn_card_validate_type
    Description: This function checks if a card type exists in the CardType table.

    Input:
        + @card_type : Card type to validate

    Output:
        + 1 if the card type exists, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_card_validate_type
    (@card_type VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM CardType
        WHERE type_name = @card_type
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END