USE BankingSystem;
GO

/*
    Function: fn_mask_bank_account_number
    Description: Masks a bank account number by preserving the first 2 digits and the last 2 digits while replacing the remaining digits with asterisks (*) in the middle part.

    Example: 123456789012 -> 12********12

    Input: VARCHAR(50) bank account number
    Output: VARCHAR(50) masked bank account number
*/
CREATE OR ALTER FUNCTION dbo.fn_mask_bank_account_number
    (@bank_account_number VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
    IF @bank_account_number IS NULL
        RETURN NULL;

    DECLARE @bank_account_length INT = LEN(@bank_account_number);

    IF @bank_account_length <= 4
        RETURN @bank_account_number;

    DECLARE @mask_length INT = @bank_account_length - 4;

    RETURN LEFT(@bank_account_number, 2)
           + REPLICATE('*', @mask_length)
           + RIGHT(@bank_account_number, 2);
END;
GO