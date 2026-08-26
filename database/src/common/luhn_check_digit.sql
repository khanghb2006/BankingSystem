USE BankingSystem;
GO

/**
    Function: fn_luhn_check_digit
    Description: This function calculates the Luhn check digit for a given number.

    Input:
        + @digits VARCHAR(20)

    Output:
        + CHAR(1) : The Luhn check digit for the input number.
*/
CREATE OR ALTER FUNCTION fn_luhn_check_digit
    (@digits VARCHAR(20))
RETURNS CHAR(1)
AS
BEGIN
    DECLARE @sum INT = 0;
    DECLARE @len INT = LEN(@digits);
    DECLARE @i INT = 1;
    DECLARE @digit INT;
    DECLARE @double BIT = 1; -- Rightmost digit is doubled

    WHILE @i <= @len
    BEGIN
        SET @digit = CAST(SUBSTRING(@digits , @len - @i + 1 , 1) AS INT);

        IF @double = 1  
        BEGIN
            SET @digit = @digit * 2;
            IF @digit > 9
                SET @digit = @digit - 9;
        END

        SET @sum = @sum + @digit;
        SET @double = 1 - @double; -- Toggle double for next digit
        SET @i = @i + 1;
    END
    RETURN CAST((10 - (@sum % 10)) % 10 AS CHAR(1));
END