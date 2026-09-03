USE BankingSystem;
GO

/*
    Function: fn_mask_citizen_id
    Description: Masks a citizen ID, keeping only the last 3 digits visible.

    Example: 012345678912 -> *********912

    Input: VARCHAR(20) citizen ID
    Output: VARCHAR(20) masked citizen ID
*/
CREATE OR ALTER FUNCTION dbo.fn_mask_citizen_id
    (@citizen_id VARCHAR(20))
RETURNS VARCHAR(20)
AS
BEGIN
    IF @citizen_id IS NULL
        RETURN NULL;

    DECLARE @len INT = LEN(@citizen_id);
    IF @len <= 3
        RETURN REPLICATE('*', @len);

    RETURN REPLICATE('*', @len - 3) + RIGHT(@citizen_id, 3);
END;
GO
