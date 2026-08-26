USE BankingSystem;
GO

/** 
    Procedure : sp_beneficiary_create
    Description : This procedure creates a new beneficiary for a specific customer.

    Input: 
        + @customer_id NCHAR(10)
        + @beneficiary_name NVARCHAR(50)
        + @bank_account_id BIGINT
        + @bank_name NVARCHAR(100)

    Output:
        + vw_BeneficiaryDetails
        + message : Success or Failure message

    Note:
        + A customer cannot save their own bank account as a beneficiary.
        + A customer cannot save the same bank account as a beneficiary more than once.
*/
CREATE OR ALTER PROCEDURE sp_beneficiary_create
    @customer_id NCHAR(10),
    @beneficiary_name NVARCHAR(50),
    @bank_account_id BIGINT,
    @bank_name NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION
            -- Validate customer id
            IF dbo.fn_customer_validate_id(@customer_id) = 0
                THROW 41000, 'Invalid customer ID.', 1;

            -- Validate bank account id
            IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
                THROW 41001, 'Invalid bank account ID.', 1;

            -- Check if the bank account belongs to the customer
            IF dbo.fn_bank_account_validate_owner(@bank_account_id, @customer_id) = 1
                THROW 41002, 'Cannot add your own bank account as a beneficiary.', 1;

            -- Check for duplicate beneficiary
            IF dbo.fn_beneficiary_validate_duplicate(@customer_id, @bank_account_id) = 1
                THROW 41003, 'Beneficiary with this bank account already exists for this customer.', 1;

            -- Insert new beneficiary record
            INSERT INTO Beneficiary 
                (customer_id, beneficiary_name, bank_account_id, bank_name , created_at)
            VALUES 
                (@customer_id, @beneficiary_name, @bank_account_id, @bank_name , GETDATE());

            IF @@ROWCOUNT = 0
                THROW 41004, 'Failed to create beneficiary.', 1;

        COMMIT TRANSACTION;
        -- Return message
        DECLARE @beneficiary_id BIGINT = SCOPE_IDENTITY();

        SELECT *,
            'Beneficiary created successfully.' AS message
        FROM BeneficiaryDetails
        WHERE beneficiary_id = @beneficiary_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END