USE BankingSystem
GO

/**
    Function : fn_account_validate_role
    Description : Check if the account role matches with expected role.
    Input:
        + @account_id : The account ID to validate
        + @expected_role : The expected role

    Output:
        + 1 : Role matches
        + 0 : Role does not match
*/
CREATE OR ALTER FUNCTION fn_account_validate_role
    (@account_id BIGINT, @expected_role VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @actual_role VARCHAR(20),
            @is_valid BIT = 0;

    SELECT @actual_role = role
    FROM Account
    WHERE account_id = @account_id;

    IF @actual_role = @expected_role
        SET @is_valid = 1;
    
    RETURN @is_valid;
END
