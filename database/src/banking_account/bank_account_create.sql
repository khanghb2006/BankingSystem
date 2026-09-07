USE BankingSystem
GO

/**
    Procedure: sp_bank_account_create
    Description: Create a new banking account for a customer.

    Input:
        + @customer_id NCHAR(10)
        + @account_type VARCHAR(20)
        + @currency NVARCHAR(10)
    
    Output:
        + vw_BankAccountDetails
        + message

    Note:
        + bank_acccount_number is randomly generated (20 digits) and guaranteed unique
        + initial_balance = 0 , available_balance = 0 , status = 'Active'
*/
CREATE OR ALTER PROCEDURE dbo.sp_bank_account_create
    @customer_id NCHAR(10),
    @account_type VARCHAR(20),
    @currency NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate customer_id
            IF dbo.fn_customer_validate_id(@customer_id) = 0
                THROW 310000, 'Invalid customer ID.', 1;

            -- Validate account_type
            IF dbo.fn_bank_account_validate_type(@account_type) = 0
                THROW 310010, 'Invalid account type.', 1;

            -- Validate currency
            IF dbo.fn_bank_account_validate_currency(@currency) = 0
                THROW 310020, 'Invalid currency.', 1;

            -- Generate unique bank account number
            DECLARE @bank_account_number NCHAR(20);
            DECLARE @is_unique BIT = 0;

            WHILE @is_unique = 0
            BEGIN
                -- CONVERT BIGINT truoc khi ABS: CHECKSUM tra int, ABS(-2147483648) se tran
                SET @bank_account_number =
                    RIGHT('0000000000' +
                        CAST(ABS(CONVERT(BIGINT, CHECKSUM(NEWID()))) AS VARCHAR(19)), 10) +
                    RIGHT('0000000000' +
                        CAST(ABS(CONVERT(BIGINT, CHECKSUM(NEWID()))) AS VARCHAR(19)), 10);

                    IF NOT EXISTS (
                        SELECT 1
                        FROM BankingAccount
                        WHERE bank_account_number = @bank_account_number
                    )
                        SET @is_unique = 1;
            END

            -- Insert new banking account
            INSERT INTO BankingAccount
                (customer_id, bank_account_number, balance, account_type, 
                    currency, available_balance, opened_at, status)
            VALUES
                (@customer_id , @bank_account_number, 0, @account_type, 
                    @currency, 0, GETDATE(), 'Active');

            IF @@ROWCOUNT = 0
                THROW 310030, 'Failed to create bank account.', 1;

        COMMIT TRANSACTION;

        DECLARE @new_bank_account_id BIGINT = SCOPE_IDENTITY();
        -- Return message
        SELECT *,
            'Bank account created successfully.' AS message
        FROM vw_BankAccountDetails
        WHERE bank_account_id = @new_bank_account_id

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
