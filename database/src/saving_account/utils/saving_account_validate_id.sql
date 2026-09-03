USE BankingSystem;
GO

/**
    Function : fn_saving_account_validate_id
    Description : Validate saving_id exists in SavingAccount table.

    Input :
        + @saving_id BIGINT : The saving_id to validate.

    Output :
        + Returns 1 if the saving_id exists, otherwise returns 0.
*/
CREATE OR ALTER FUNCTION fn_saving_account_validate_id
    (@saving_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM SavingAccount
        WHERE saving_id = @saving_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
