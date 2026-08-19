/*
    Employee - Create Profile
    Description: Create new employee profile in the database
*/

USE BankingSystem
GO

/*
    Input:
        @account_id : Account ID
        @branch_id : Branch ID
        @full_name : Full Name of the employee
        @dob : Date of Birth
        @gender : Gender of the employee
        @citizen_id : Citizen ID of the employee
        @address : Address of the employee
        @position : Position of the employee

    Output:
        + vw_EmployeeDetails
        + message : Success or Failure message
*/
CREATE OR ALTER PROCEDURE sp_employee_create_profile
    @account_id BIGINT,
    @branch_id NCHAR(10),
    @full_name NVARCHAR(100),
    @dob DATE,
    @gender VARCHAR(10),
    @citizen_id VARCHAR(20),
    @address NVARCHAR(255),
    @position VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION
            -- Validate account id
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 90000, 'Invalid account ID.', 1;

            -- Validate account role
            IF dbo.fn_account_validate_role(@account_id, 'Employee') = 0
                THROW 90001, 'Invalid account role. Account must be an Employee.', 1;

            -- Validate account status
            IF dbo.fn_account_validate_status(@account_id, 'Active') = 0
                THROW 90002, 'Invalid account status. Account must be Active.', 1;

            -- Validate employee profile existence
            IF dbo.fn_employee_validate_exists(@account_id) = 1
                THROW 90003, 'Employee profile already exists for this account.', 1;

            -- Validate branch id
            IF dbo.fn_branch_validate_id(@branch_id) = 0
                THROW 90004, 'Invalid branch ID.', 1;

            -- Validate citizen id
            IF dbo.fn_employee_validate_citizen_id(@citizen_id) = 1
                THROW 90005, 'Invalid citizen ID.', 1;

            -- Validate Position
            IF dbo.fn_employee_validate_position(@position) = 0
                THROW 90006, 'Invalid position.', 1;

            -- Generate employee id
            DECLARE @employee_id NCHAR(10) = 'EMP' +
                RIGHT('0000000' + CAST(NEXT VALUE FOR seq_EmployeeID AS VARCHAR(7)), 7);

            -- Insert new employee profile
            INSERT INTO Employee
                (employee_id , account_id , branch_id , position , full_name,
                    dob, gender , citizen_id , address , status , hired_at , created_at)
            VALUES
                (@employee_id, @account_id, @branch_id, @position, @full_name,
                    @dob, @gender, @citizen_id, @address, 'Active', GETDATE(), GETDATE());

            IF @@ROWCOUNT = 0
                THROW 90007, 'Failed to create employee profile.', 1;

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            'Employee profile created successfully.' AS message
        FROM vw_EmployeeDetails
        WHERE account_id = @account_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END
