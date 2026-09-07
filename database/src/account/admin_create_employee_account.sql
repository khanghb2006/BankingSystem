USE BankingSystem
GO

/**
    Procedure : sp_admin_create_employee_account
    Description : Admin tao tai khoan dang nhap cho nhan vien
        (role = 'Employee', status = 'Active'). Khong qua luong OTP vi
        admin la nguoi tin cay. Sau do goi sp_employee_create_profile.

    Input:
        + @username     VARCHAR(50)
        + @email        NVARCHAR(100)
        + @phone_number VARCHAR(20)
        + @password     VARCHAR(255)   -- hash BCrypt do Spring truyen vao

    Output:
        + vw_Account (dong vua tao)
        + message

    Note:
        + Ai duoc goi proc nay (kiem tra role Admin) do tang Spring Boot lo.
*/
CREATE OR ALTER PROCEDURE dbo.sp_admin_create_employee_account
    @username     VARCHAR(50),
    @email        NVARCHAR(100),
    @phone_number VARCHAR(20),
    @password     VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF dbo.fn_account_validate_username(@username) = 1
                THROW 170000, 'Username already exists.', 1;

            IF dbo.fn_account_validate_email(@email) = 1
                THROW 170010, 'Email already exists.', 1;

            IF dbo.fn_account_validate_phone_number(@phone_number) = 1
                THROW 170020, 'Phone number already exists.', 1;

            INSERT INTO Account
                (username, email, phone_number, password_hash,
                    role, created_at, updated_at, status)
            VALUES
                (@username, @email, @phone_number, @password,
                    'Employee', GETDATE(), NULL, 'Active');

            IF @@ROWCOUNT = 0
                THROW 170030, 'Failed to create employee account.', 1;

        COMMIT TRANSACTION;

        SELECT *,
            'Employee account created. Next step: create the employee profile.' AS message
        FROM vw_Account
        WHERE username = @username;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
