USE BankingSystem;
GO

/**
    Procedure: sp_bank_account_search
    Description: Search for bank accounts based on various criteria.
    
    Input:
        + @bank_account_number : Partial or full bank account number to search for (optional).
        + @customer_id : Exact customer id to search for (optional).
        + @account_type : Account type to filter by (optional).
        + @status : Account status to filter by (optional).

    Output:
        + vw_BankAccountSummary rows matching the given criteria

    Note :
        + At least one of @bank_account_number or @customer_id must be provided.
        + @bank_account_number is matched as a partial (contains) search.
        + @account_type and @customer_id are matched exactly.
*/
CREATE OR ALTER PROCEDURE sp_bank_account_search
    @bank_account_number NVARCHAR(20) = NULL,
    @customer_id NCHAR(10) = NULL,
    @account_type VARCHAR(20) = NULL,
    @status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @bank_account_number IS NULL AND @customer_id IS NULL
            THROW 30010, 'At least one of bank_account_number or customer_id must be provided.', 1;

        -- Validate account_type
        IF @account_type IS NOT NULL AND dbo.fn_bank_account_validate_type(@account_type) = 0
            THROW 30011, 'Invalid account type.', 1;

        -- Validate status
        IF @status IS NOT NULL AND dbo.fn_bank_account_validate_status(@status) = 0
            THROW 30012, 'Invalid status.', 1;

        SELECT S.*
        FROM vw_BankAccountSummary S
        JOIN BankingAccount BA ON BA.bank_account_id = S.bank_account_id
        WHERE (@bank_account_number IS NULL OR BA.bank_account_number LIKE '%' + @bank_account_number + '%')
            AND (@customer_id IS NULL OR BA.customer_id = @customer_id)
            AND (@account_type IS NULL OR BA.account_type = @account_type)
            AND (@status IS NULL OR BA.status = @status)
        ORDER BY BA.bank_account_number;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
