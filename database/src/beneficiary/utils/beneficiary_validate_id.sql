USE BankingSystem;
GO

/** 
    Function : fn_beneficiary_validate_id
    Description : This function validates the existence of a beneficiary ID.

    Input: 
        + @beneficiary_id BIGINT

    Output:
        + is_valid : 1 if the beneficiary exists, 0 otherwise
*/
CREATE OR ALTER FUNCTION fn_beneficiary_validate_id
    (@beneficiary_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1 
        FROM Beneficiary 
        WHERE beneficiary_id = @beneficiary_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END;