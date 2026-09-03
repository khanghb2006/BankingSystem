USE BankingSystem;
GO

/** 
    Procedure : sp_beneficiary_get_details
    Description : This procedure retrieves the details of a specific beneficiary for a given customer.
    
    Input: 
        + @beneficiary_id BIGINT

    Output:
        + vw_BeneficiaryDetails
*/
CREATE OR ALTER PROCEDURE sp_beneficiary_get_details
    @beneficiary_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate beneficiary id
        IF dbo.fn_beneficiary_validate_id(@beneficiary_id) = 0
            THROW 420000, 'Invalid beneficiary ID.', 1;

        -- Retrieve beneficiary details
        SELECT *
        FROM vw_BeneficiaryDetails
        WHERE beneficiary_id = @beneficiary_id;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;