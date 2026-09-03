USE BankingSystem;
GO

/**
    Procedure : sp_saving_account_settle_matured
    Description : Flip every 'Active' saving account whose maturity date has
        passed to 'Matured'. Intended to be run on a schedule by the application.

    Input:
        + (none)

    Output:
        + matured_count : number of saving accounts moved to 'Matured'.
        + message

    Note:
        + Interest is paid when the customer closes the deposit
          (sp_saving_account_close); this procedure only updates the status.
*/
CREATE OR ALTER PROCEDURE dbo.sp_saving_account_settle_matured
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        UPDATE SavingAccount
        SET status = 'Matured'
        WHERE status = 'Active'
            AND maturity_date <= CAST(GETDATE() AS DATE);

        SELECT @@ROWCOUNT AS matured_count,
            'Matured saving accounts updated.' AS message;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
