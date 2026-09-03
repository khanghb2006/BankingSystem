USE BankingSystem;
GO

/**
    Function : fn_saving_account_validate_status
    Description : Validate status exists in SavingAccountStatus table.

    Input :
        + @status VARCHAR(20) : The status to validate.

    Output :
        + Returns 1 if the status exists, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_saving_account_validate_status
    (@status VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM SavingAccountStatus
        WHERE status_name = @status
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
