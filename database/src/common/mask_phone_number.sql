USE BankingSystem;
GO

/*
    Function: fn_mask_phone_number
    Description: Masks a phone number by replacing the first 7 digits with asterisks (*) and preserving the last 3 digits.

    Example: 0901234567 -> *******567

    Input: VARCHAR(20) phone number
    Output: VARCHAR(20) masked number
*/
CREATE OR ALTER FUNCTION dbo.fn_mask_phone_number
    (@phone_number VARCHAR(20))
RETURNS VARCHAR(20)
AS
BEGIN
    IF @phone_number IS NULL
        RETURN NULL;
    DECLARE @phone_length INT = LEN(@phone_number);
    IF @phone_length <= 7
        RETURN REPLICATE('*', @phone_length);
    RETURN REPLICATE('*', 7) + RIGHT(@phone_number, 3);
END;
GO