USE BankingSystem;
GO

/**
    Procedure : sp_saving_account_get_details
    Description : Retrieve the details of a single saving account.

    Input:
        + @customer_id NCHAR(10) : The customer who owns the saving account.
        + @saving_id BIGINT : The saving account to retrieve.

    Output:
        + vw_SavingAccountDetails
*/
CREATE OR ALTER PROCEDURE dbo.sp_saving_account_get_details
    @customer_id NCHAR(10),
    @saving_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validate saving account ID
        IF dbo.fn_saving_account_validate_id(@saving_id) = 0
            THROW 351000, 'Invalid saving account ID.', 1;

        -- Validate the customer owns this saving account
        IF dbo.fn_saving_account_validate_owner(@saving_id, @customer_id) = 0
            THROW 351010, 'This saving account does not belong to the given customer.', 1;

        -- Retrieve saving account details
        SELECT *
        FROM vw_SavingAccountDetails
        WHERE saving_id = @saving_id;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
