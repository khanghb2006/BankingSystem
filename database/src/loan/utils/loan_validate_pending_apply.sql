USE BankingSystem
GO

/** 
    Function: fn_loan_validate_pending_apply
    Description: This function checks if a customer has any pending loan applications. 

    Input:
        + @customer_id NCHAR(10) : The ID of the customer to check for pending loan applications.

    Output:
        + Returns 1 if there is a pending application, otherwise it returns 0.
*/
CREATE OR ALTER FUNCTION fn_loan_validate_pending_apply
    (@customer_id NCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @has_pending BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Loan
        WHERE customer_id = @customer_id 
            AND status = 'Pending'
    )
        SET @has_pending = 1;

    RETURN @has_pending;
END;