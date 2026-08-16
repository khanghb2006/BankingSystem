/* 
    Customer - Create Profile
    Description: This procedure creates a new customer profile in the banking system.
*/

USE BankingSystem;
GO

/*
    Parameters:
        + @account_id: The unique identifier for the account.
        + @branch_id: The unique identifier for the branch.
        + @full_name: The full name of the customer.
        + @dob: The date of birth of the customer.
        + @gender: The gender of the customer.
        + @citizen_id: The citizen ID of the customer.
        + @address: The address of the customer.
    
    Returns:
        + customer_id
        + account_id
        + branch_id
        + full_name
        + dob
        + gender
        + citizen_id
        + address
        + status
        + message

    Note : 
        + Account must be Active
        + Account role must be Customer
        + Customer profie can be created only once for each account
*/
CREATE OR ALTER PROCEDURE sp_create_customer_profile
    @account_id BIGINT,
    @branch_id BIGINT,
    @full_name NVARCHAR(255),
    @dob DATE,
    @gender VARCHAR(10),
    @citizen_id VARCHAR(20),
    @address NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate Account ID
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 50010, 'Invalid account_id. Account does not exist.', 1;
            
            -- Validate Account Role
            IF dbo.fn_account_validate_role(@account_id, 'Customer') = 0
                THROW 50011, 'Invalid account role. Account must be a Customer.', 1;

            -- Validate Account Status
            IF dbo.fn_account_validate_status(@account_id, 'Active') = 0
                THROW 50012, 'Invalid account status. Account must be Active.', 1;

            -- Validate Customer Profile Existence
            IF dbo.fn_customer_validate_exists(@account_id) = 1
                THROW 50013, 'Customer profile already exists for this account.', 1;

            -- Validate Branch ID
            IF dbo.fn_branch_validate_id(@branch_id) = 0
                THROW 50014, 'Invalid branch_id. Branch does not exist.', 1;

            -- Validate Customer's Citizen ID
            IF dbo.fn_customer_validate_citizen_id(@citizen_id) = 1
                THROW 50015, 'Invalid citizen_id. Citizen ID already exists.', 1;

            -- Generate new customer_id using sequence
            DECLARE @customer_id NCHAR(10) = 'CIF' + 
                RIGHT('0000000' + CAST(NEXT VALUE FOR seq_CustomerID AS VARCHAR(7)), 7);
            
            -- Create customer profie
            INSERT INTO Customer
                (customer_id, account_id, branch_id, full_name, dob, gender, citizen_id, address, created_at)
            VALUES
                (@customer_id, @account_id, @branch_id, @full_name, @dob, @gender, @citizen_id, @address, GETDATE());

            IF @@ROWCOUNT = 0
                THROW 50016, 'Failed to create customer profile.', 1;
        COMMIT TRANSACTION;

        -- Return the newly created customer profile
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
            'Customer profile created successfully.' AS message
        FROM Customer
        WHERE customer_id = @customer_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END