/* 
    Customer : Get Summary
    Description: Summary information for the authenticated customer and used for dashboard display.
*/

USE BankingSystem;
GO

/* 
    Parameters:
        + @customer_id : Customer ID

    Returns:
        + customer_id
        + full_name
        + email
        + phone_number
        + number_of_accounts
        + number_of_cards
*/
CREATE OR ALTER PROCEDURE sp_customer_get_summary
    @customer_id NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        -- Validate customer id
        IF dbo.fn_customer_validate_id(@customer_id) = 0
            THROW 80000, 'Invalid customer ID.', 1;

        SELECT
            C.customer_id,
            C.full_name,
            A.email,
            A.phone_number,
            
            -- Number of banking accounts
            (
                SELECT COUNT(*)
                FROM BankingAccount BA
                WHERE BA.customer_id = C.customer_id
            ) as number_of_banking_accounts,

            -- Number of cards
            (
                SELECT COUNT(*)
                FROM Card CA
                INNER JOIN BankingAccount BA ON CA.bank_account_id = BA.bank_account_id
                WHERE BA.customer_id = C.customer_id
            ) as number_of_cards
        FROM Customer C
        LEFT JOIN Account A ON C.account_id = A.account_id
        WHERE C.customer_id = @customer_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END