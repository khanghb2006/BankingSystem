USE BankingSystem
GO

/*
    Function : fn_validate_citizen_id
    Description : Check if the citizen ID is valid.
*/
CREATE OR ALTER FUNCTION fn_validate_citizen_id
    (@citizen_id VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Customer
        WHERE citizen_id = @citizen_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END