USE BankingSystem
GO

/* 
    Function : fn_validate_account_role
    Description : Check if the account role is matches
        with expected role.
*/
CREATE OR ALTER FUNCTION fn_validate_account_role
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
