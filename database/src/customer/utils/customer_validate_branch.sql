USE BankingSystem;
GO

/**
    Function : fn_customer_validate_branch
    Description : This function checks if a customer belongs to a specific branch.

    Input:
        + @customer_id : The unique identifier of the customer to validate.
        + @branch_id : The branch to validate against.

    Output:
        + 1 if the customer belongs to the specified branch, 0 otherwise.

    Note :
        + This function is used to validate if a customer belongs to a specific branch.
*/

CREATE OR ALTER FUNCTION fn_customer_validate_branch
(
    @customer_id NCHAR(10),
    @branch_id NCHAR(10)
)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id AND branch_id = @branch_id
    )
    BEGIN
        SET @result = 1;
    END

    RETURN @result;
END