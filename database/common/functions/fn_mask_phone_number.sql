USE BankingSystem
GO

/*
------------------------------------------------------
    Function: fn_mask_phone_number
    Description : Mask phone number for privacy
------------------------------------------------------
*/
CREATE OR ALTER FUNCTION fn_mask_phone_number
    (@phone_number VARCHAR(20))
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @masked_phone_number VARCHAR(20)
    SET @masked_phone_number = CONCAT (
        REPLICATE('*', LEN(@phone_number) - 3),
        RIGHT(@phone_number , 3)
    )
    RETURN @masked_phone_number
END