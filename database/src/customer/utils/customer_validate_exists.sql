USE BankingSystem
GO

/* 
    Function : fn_customer_validate_exists
    Description : Check if the customer profile is exists.
*/
CREATE OR ALTER FUNCTION fn_customer_validate_exists
    (@account_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Customer
        WHERE account_id = @account_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END
