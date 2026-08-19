/* 
    Customer - Get Profie Information
    Description: This procedure retrieves the profile information of a customer based on the provided account ID. 
*/

USE BankingSystem;
GO

/* 
    Input:
        + @account_id : Account ID

    Output:
        + vw_CustomerProfile : Customer profile information
*/
CREATE OR ALTER PROCEDURE sp_customer_get_profile
    @account_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validate account
        IF dbo.fn_account_validate_id(@account_id) = 0
            THROW 50010, 'Invalid account ID.', 1;
        
        -- Validate account role
        IF dbo.fn_account_validate_role(@account_id, 'Customer') = 0
            THROW 50011, 'Account role must be Customer.', 1;


        -- Retrieve customer profile information
        SELECT *
        FROM vw_CustomerDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END