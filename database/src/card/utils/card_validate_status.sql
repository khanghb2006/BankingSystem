USE BankingSystem;
GO

/**
    Function: fn_card_validate_status
    Description: This function checks if a card status exists in the CardStatus table.

    Input:
        + @card_status : Card status to validate

    Output:
        + 1 if the card status exists, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_card_validate_status
    (@card_status NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM CardStatus
        WHERE status_name = @card_status
    )
        SET @is_valid = 1;
    RETURN @is_valid;
END