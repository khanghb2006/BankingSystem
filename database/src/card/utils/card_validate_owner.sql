USE BankingSystem;
GO

/** 
    Function: fn_card_validate_owner
    Description: This function checks if a card belongs to a specific customer.

    Input:
        + @card_number : Card number to validate
        + @bank_account_id : Bank account ID to validate

    Output:
        + 1 if the card belongs to the bank account, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_card_validate_owner
    (@card_number VARCHAR(20), @bank_account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Card
        WHERE card_number = @card_number 
            AND bank_account_id = @bank_account_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END