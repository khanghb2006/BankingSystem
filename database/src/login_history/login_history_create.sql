USE BankingSystem;
GO

/** 
    Procedure : sp_login_history_create
    Description : This stored procedure is used to create a new login history record.

    Input:
        + @account_id BIGINT : The ID of the account
        + @login_time DATETIME : The time of the login attempt (optional, defaults to current time).
        + @ip_address VARCHAR(50) : The IP address from which the login attempt was made.
        + @device NVARCHAR(100) : The device used for the login attempt
        + @login_status VARCHAR(20) : The status of the login attempt 
    
    Output:
        + vw_LoginHistoryDetails
        + message
*/
CREATE OR ALTER PROCEDURE sp_login_history_create
    @account_id BIGINT,
    @login_time DATETIME = NULL,
    @ip_address VARCHAR(50),
    @device NVARCHAR(100),
    @login_status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 101000, 'Account does not exist.', 1;

            -- Validate login status
            IF dbo.fn_login_history_validate_status(@login_status) = 0
                THROW 101001, 'Invalid login status.', 1;

            -- Insert new login history record
            INSERT INTO LoginHistory 
                (account_id, login_time, ip_address, device, login_status)
            VALUES
                (@account_id, COALESCE(@login_time, GETDATE()), @ip_address, @device, @login_status);

            IF @@ROWCOUNT = 0
                THROW 101002, 'Failed to create login history record.', 1;
        COMMIT TRANSACTION;

        DECLARE @new_login_id BIGINT = SCOPE_IDENTITY();

        -- Return message
        SELECT *,
            'Login history record created successfully.' AS message
        FROM vw_LoginHistoryDetails
        WHERE login_id = @new_login_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO