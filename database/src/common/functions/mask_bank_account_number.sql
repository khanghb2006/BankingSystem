USE BankingSystem
GO

/*
------------------------------------------------------
    Function: fn_mask_bank_account_number
    Description : Mask bank account number for privacy
------------------------------------------------------
*/
CREATE OR ALTER FUNCTION fn_mask_bank_account_number
    (@bank_account_number NCHAR(20))
RETURNS NCHAR(20)
AS
BEGIN
    DECLARE @masked_bank_account_number NCHAR(20)
    SET @masked_bank_account_number = CONCAT (
        LEFT(@bank_account_number, 4),
        REPLICATE('*' , LEN(@bank_account_number) - 8),
        RIGHT(@bank_account_number, 4)
    )
    RETURN @masked_bank_account_number
END