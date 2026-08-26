USE BankingSystem
GO

/**
    Procedure: sp_card_create
    Description: This procedure creates a new card for a customer.

    Input:
        + @bank_account_id BIGINT : The ID of the banking account for which the card is being created.
        + @card_type VARCHAR(20) : The type of card to be created (e.g., 'Debit', 'Credit').

    Output:
        + vw_CardDetails 
        + message : Success or Failure message

    Note:
        +  card_number is 16 digits : 6 digits BIN prefix (by card_type) +
            9 digits random number + 1 digit Luhn check digit
        + cvv_hash here is generated server-side for demo purposes only;
          in practice the app should hash a CVV it generated/showed once
          and pass the hash in, never store/return the plaintext CVV
*/
CREATE OR ALTER PROCEDURE sp_card_create
    @bank_account_id BIGINT,
    @card_type VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION

            -- Validate bank account id
            IF dbo.fn_bank_account_validate_id(@bank_account_id) = 0
                THROW 61000, 'Invalid bank account ID.', 1;

            -- Validate Card Type
            IF dbo.fn_card_validate_type(@card_type) = 0
                THROW 61001, 'Invalid card type.', 1;

            -- BIN prefix 
            DECLARE @bin_prefix VARCHAR(6) = 
                dbo.fn_card_get_bin_prefix(@card_type);

            -- Generate a unique 16 digits card number
            DECLARE @body VARCHAR(9);
            DECLARE @check_digit CHAR(1);
            DECLARE @card_number VARCHAR(20);
            DECLARE @is_unique BIT = 0;

            WHILE @is_unique = 0
            BEGIN
                SET @body = RIGHT('000000000' +
                    CAST(ABS(CHECKSUM(NEWID())) % 1000000000 AS VARCHAR(9)), 9);

                SET @check_digit = dbo.fn_luhn_check_digit(@bin_prefix + @body);
                SET @card_number = @bin_prefix + @body + @check_digit;

                IF dbo.fn_card_validate_number(@card_number) = 0
                    SET @is_unique = 1;
            END

            -- Generate and hash a cvv
            DECLARE @cvv VARCHAR(3) = RIGHT('000' + 
                CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(3)), 3);
            DECLARE @cvv_hash VARCHAR(255) = 
                CONVERT(VARCHAR(255) , HASHBYTES('SHA2_256', @cvv), 2);

            -- Insert new card  
            INSERT INTO Card
                (bank_account_id, card_number, card_type, expired_at, 
                    cvv_hash, issued_at, status)
            VALUES
                (@bank_account_id, @card_number, @card_type, 
                    DATEADD(YEAR, 5, GETDATE()), @cvv_hash, GETDATE(), 'Active');

            IF @@ROWCOUNT = 0
                THROW 61002, 'Failed to create card.', 1;
                
        COMMIT TRANSACTION;
        -- Return message
        DECLARE @card_id BIGINT = SCOPE_IDENTITY();

        SELECT *,
            'Card created successfully.' AS message
        FROM vw_CardDetails
        WHERE card_id = @card_id;      
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END