/*
    Customer - Update Profie
    Decription: This stored procedure updates the profile information of a customer in the database.
*/
USE BankingSystem;
GO

/* 
    Parameters:
        + @account_id : Account ID
        + @full_name : New full name (optional)
        + @dob : New date of birth (optional)
        + @gender : New gender (optional)
        + @address : New address (optional)

    Returns:
        + customer_id
        + account_id
        + branch_id
        + full_name
        + dob 
        + gender
        + citizen_id
        + address
        + created_at
        + updated_at
        + message
    
    Note:
        + Only active Customer can update their profile information.
        + Only provided fields will be updated, others will remain unchanged.
        + Customer cannot change customer_id, account_id, branch_id, citizen_id, created_at.
*/
CREATE OR ALTER PROCEDURE sp_customer_update_profile
    @account_id BIGINT,
    @full_name NVARCHAR(100) = NULL,
    @dob DATE = NULL,
    @gender VARCHAR(10) = NULL,
    @address NVARCHAR(255) = NULL
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 50020, 'Invalid account ID.', 1;
            
            -- Validate account role
            IF dbo.fn_account_validate_role(@account_id, 'Customer') = 0
                THROW 50021, 'Account role must be Customer.', 1;

            -- Validate account status
            IF dbo.fn_account_validate_status(@account_id, 'Active') = 0
                THROW 50022, 'Account status must be Active.', 1;

            -- Validate customer profile existence
            IF dbo.fn_customer_validate_exists(@account_id) = 0
                THROW 50023, 'Customer profile does not exist.', 1;
            
            -- Check whether there is anything to update
            IF @full_name IS NULL
                AND @dob IS NULL
                AND @gender IS NULL
                AND @address IS NULL
                THROW 50024, 'No fields provided for update.', 1;

            -- Update profie fields if provided
            UPDATE Customer
            SET
                full_name = COALESCE(@full_name, full_name),
                dob = COALESCE(@dob, dob),
                gender = COALESCE(@gender, gender),
                address = COALESCE(@address, address),
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 50025, 'No rows were updated. Please check the provided fields.', 1;

        COMMIT TRANSACTION;

        -- Return the updated customer profile
        SELECT 
            customer_id,
            account_id,
            branch_id,
            full_name,
            dob,
            gender,
            citizen_id,
            address, 
            created_at,
            updated_at,
            'Customer profile updated successfully.' AS MESSAGE
        FROM Customer
        WHERE account_id = @account_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END