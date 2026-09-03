USE BankingSystem
GO

/**
    Procedure: sp_beneficiary_update
    Description: Update the nickname of a saved beneficiary.

    Input:
        + @beneficiary_id BIGINT
        + @customer_id NCHAR(10)
        + @beneficiary_name NVARCHAR(50)

    Output:
        + vw_BeneficiaryDetails
        + message

    Note:
        + Only beneficiary_name can be changed. bank_account_id/bank_name
          are not editable — if the destination account changes, the
          customer should delete this beneficiary and add a new one.
        + @customer_id is required to verify the beneficiary belongs to
          the customer making the request (prevents editing someone
          else's saved beneficiary).
*/
CREATE OR ALTER PROCEDURE dbo.sp_beneficiary_update
    @beneficiary_id BIGINT,
    @customer_id NCHAR(10),
    @beneficiary_name NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate beneficiary_id
            IF dbo.fn_beneficiary_validate_id(@beneficiary_id) = 0
                THROW 440000, 'Invalid beneficiary ID.', 1;

            -- Validate ownership
            IF dbo.fn_beneficiary_validate_owner(@beneficiary_id, @customer_id) = 0
                THROW 440010, 'This beneficiary does not belong to the given customer.', 1;

            -- Update beneficiary name
            UPDATE Beneficiary
            SET beneficiary_name = @beneficiary_name
            WHERE beneficiary_id = @beneficiary_id;

            IF @@ROWCOUNT = 0
                THROW 440020, 'Failed to update beneficiary.', 1;

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Beneficiary updated successfully.' AS message
        FROM vw_BeneficiaryDetails
        WHERE beneficiary_id = @beneficiary_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO