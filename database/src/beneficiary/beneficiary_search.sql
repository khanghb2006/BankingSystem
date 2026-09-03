USE BankingSystem;
GO

/**
    Procedure : sp_beneficiary_search
    Description : This stored procedure searches for beneficiaries based on the provided search criteria.

    Input: 
        + @customer_id NCHAR(10)
        + @beneficiary_name NVARCHAR(50) (optional)

    Output: 
        + vw_BeneficiaryDetails
*/
CREATE OR ALTER PROCEDURE dbo.sp_beneficiary_search
    @customer_id NCHAR(10),
    @beneficiary_name NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate customer id
        IF dbo.fn_customer_validate_id(@customer_id) = 0
            THROW 430000, 'Invalid customer ID.', 1;

        -- Search for beneficiaries
        SELECT *
        FROM vw_BeneficiaryDetails
        WHERE customer_id = @customer_id
            AND (@beneficiary_name IS NULL 
                OR beneficiary_name LIKE '%' + @beneficiary_name + '%');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END