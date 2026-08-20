USE BankingSystem
GO

/**     
    Procedure : sp_bank_account_get_details
    Description: Get the details of a bank account by its id.

    Input :
        + @bank_account_id BIGINT : The bank account id to retrieve details for.
    
    Output: 
        + Returns the details of the bank account if it exists, otherwise returns an empty result set.
*/
CREATE OR ALTER PROCEDURE sp_bank_account_get_details
    @bank_account_id BIGINT
AS
BEGIN
    BEGIN TRY
        -- Validate the bank account id
        IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
            THROW 50000, 'Bank account id does not exist.', 1;

        -- Retrieve the bank account details
        SELECT * 
        FROM vw_BankingAccountDetails 
        WHERE BankAccountId = @bank_account_id
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO