USE BankingSystem;
GO

/** 
    Function : card_get_bin_prefix
    Description : This function returns the BIN prefix for a given card type.

    Input:
        + @card_type : The type of card (e.g., 'Debit', 'Credit').
    
    Output:
        + VARCHAR(6) : The BIN prefix associated with the card type.
*/
CREATE OR ALTER FUNCTION fn_card_get_bin_prefix
    (@card_type VARCHAR(20))
RETURNS VARCHAR(6)
AS
BEGIN
    DECLARE @bin_prefix VARCHAR(6);

    SET @bin_prefix = 
        CASE @card_type
            WHEN 'Debit' THEN '400000'
            WHEN 'Credit' THEN '520000'
            ELSE NULL
        END;

    RETURN @bin_prefix;
END