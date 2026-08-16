USE BankingSystem
GO

/* 
------------------------------------------------------
    Function: fn_mask_email
    Description : Mask email for privacy
------------------------------------------------------
*/

CREATE OR ALTER FUNCTION fn_mask_email(@email NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @masked_email NVARCHAR(100)
    SET @masked_email = CONCAT (
        LEFT(@email, 3),
        REPLICATE('*' , CHARINDEX('@', @email) - 3),
        RIGHT(@email, LEN(@email) - CHARINDEX('@', @email) + 1)
    )
    RETURN @masked_email
END