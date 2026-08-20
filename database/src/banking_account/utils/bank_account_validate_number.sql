USE BankingSystem
GO

/** 
    Function : fn_bank_account_validate_number
    Description : Check if the bank account number exists in the database

    Input :
        + @bank_account_number
    
    Output :
        + 1 : Bank account number exists
        + 0 : Bank account number does not exist
*/
CREATE OR ALTER FUNCTION fn_bank_account_validate_number
    (@bank_account_number NCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @exists BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM BankingAccount
        WHERE bank_account_number = @bank_account_number
    )
        SET @exists = 1;
    
    RETURN @exists;
END