USE BankingSystem;
GO

/**
    Function: fn_card_validate_number
    Description: Validates a card number exists in the Card table.

    Input:
        @card_number : Card number to validate

    Output:
        + 1 if the card number is valid, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_card_validate_number
    (@card_number VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Card
        WHERE card_number = @card_number
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END 