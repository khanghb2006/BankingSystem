USE BankingSystem
GO

/* 
    Function : fn_customer_validate_id
    Description : Check if the customer id is valid.
*/
CREATE OR ALTER FUNCTION fn_customer_validate_id
    (@customer_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        SET @is_valid = 1;

    RETURN @is_valid;
END