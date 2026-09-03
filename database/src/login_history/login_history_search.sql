USE BankingSystem;
GO

/** 
    Procedure: sp_login_history_search
    Description: This stored procedure is used to search for login history records based on various criteria.

    Input :
        + @account_id BIGINT : The ID of the account for which to search login history.
        + @login_status VARCHAR(20) : The status of the login attempts to filter by (optional).
        + @ip_address VARCHAR(50) : The IP address to filter by (optional).
        + @device NVARCHAR(100) : The device to filter by (optional).
        + @start_date DATETIME : The start date for the search range.
        + @end_date DATETIME : The end date for the search range.
    
    Output :
        + vw_LoginHistoryDetails
*/
CREATE OR ALTER PROCEDURE dbo.sp_login_history_search
    @account_id BIGINT,
    @login_status VARCHAR(20) = NULL,
    @ip_address VARCHAR(50) = NULL,
    @device NVARCHAR(100) = NULL,
    @start_date DATETIME = NULL,
    @end_date DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate account id
        IF dbo.fn_account_validate_id(@account_id) = 0
            THROW 102000, 'Account does not exist.', 1;

        -- Validate login status if provided
        IF @login_status IS NOT NULL AND dbo.fn_login_history_validate_status(@login_status) = 0
            THROW 102001, 'Invalid login status.', 1;

        -- Validate date range if provided
        IF @start_date IS NOT NULL AND @end_date IS NOT NULL AND @start_date > @end_date
            THROW 102002, 'Start date cannot be later than end date.', 1;

        -- Search for login history records based on the provided criteria
        SELECT *
        FROM vw_LoginHistoryDetails
        WHERE account_id = @account_id
            AND (@login_status IS NULL OR login_status = @login_status)
            AND (@ip_address IS NULL OR ip_address = @ip_address)
            AND (@device IS NULL OR device = @device)
            AND (@start_date IS NULL OR login_time >= @start_date)
            AND (@end_date IS NULL OR login_time <= @end_date)
        ORDER BY login_time DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO