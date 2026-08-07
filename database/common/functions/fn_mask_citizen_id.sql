USE BankingSystem
GO

/*
    Function: fn_mask_citizen_id
    Description : Mask citizen ID for privacy
*/ 

CREATE OR ALTER FUNCTION fn_mask_citizen_id(@citizen_id VARCHAR(20))
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @masked_id VARCHAR(20)
    SET @masked_id = CONCAT (
        REPLICATE('*', LEN(@citizen_id) - 4), 
        RIGHT(@citizen_id, 4)
    )
    RETURN @masked_id
END