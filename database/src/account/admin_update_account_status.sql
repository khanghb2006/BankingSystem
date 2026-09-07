USE BankingSystem
GO

/**
    Procedure : sp_admin_update_account_status
    Description : Admin doi trang thai tai khoan dang nhap.
        Dung cho: khoa tai khoan (Locked), vo hieu hoa (Disabled),
        mo lai (Active).

    Input:
        + @account_id BIGINT
        + @new_status VARCHAR(20)   -- phai co trong AccountStatus:
                                    --   Pending / Active / Disabled / Locked

    Output:
        + vw_Account (dong vua cap nhat)
        + message

    Note:
        + Kiem tra nguoi goi la Admin do tang Spring Boot lo.
        + Khong ghi lai "ai doi" vi schema chua co bang audit.
*/
CREATE OR ALTER PROCEDURE dbo.sp_admin_update_account_status
    @account_id BIGINT,
    @new_status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 171000, 'Invalid account ID.', 1;

            IF NOT EXISTS (SELECT 1 FROM AccountStatus WHERE status_name = @new_status)
                THROW 171010, 'Invalid account status.', 1;

            UPDATE Account
            SET status     = @new_status,
                updated_at = GETDATE()
            WHERE account_id = @account_id;

            IF @@ROWCOUNT = 0
                THROW 171020, 'Failed to update account status.', 1;

        COMMIT TRANSACTION;

        SELECT *,
            'Account status updated.' AS message
        FROM vw_Account
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
