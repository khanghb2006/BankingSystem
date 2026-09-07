USE BankingSystem;
GO

/** 
    1. Branch Seed - Use to test sp_branch_create
*/
EXEC dbo.sp_branch_create
    @branch_name = N'Chi nhanh Quan 1',
    @address = N'123 Nguyen Hue, Quan 1, TP.HCM',
    @phone_number = '0123456789';

-- Test the procedure is actually working
DECLARE @branch_id NCHAR(10);
SELECT @branch_id = branch_id
FROM Branch
WHERE branch_name = N'Chi nhanh Quan 1';


/**
    2. Customer Seed - Use to test sp_account_register, otp , activate, sp_customer_create
*/

-- Customer : Khang Huynh
EXEC dbo.sp_account_register
    @username = 'khanghb2006', 
    @email = N'khanghb2006@gmail.com',
    @phone_number = '0123456789',
    @password = 'hashed_password_here'; 

DECLARE @khang_account BIGINT;
SELECT @khang_account = account_id
FROM Account
WHERE username = 'khanghb2006';

EXEC dbo.sp_otp_generate_otpcode 
    @account_id = @khang_account,
    @purpose = 'Register';

DECLARE @khang_otp_code NCHAR(6);
SELECT @khang_otp_code = otp_code
FROM OTP
WHERE account_id = @khang_account
    AND purpose = 'Register'
    AND verified = 0;

-- Verify OTP code
EXEC dbo.sp_otp_verify
    @account_id = @khang_account,
    @otp_code = @khang_otp_code,
    @purpose = 'Register';

EXEC dbo.sp_account_activate
    @account_id = @khang_account;

-- Create customer profile
EXEC dbo.sp_create_customer_profile
    @account_id = @khang_account,
    @branch_id = @branch_id,
    @full_name = N'Huynh Bao Khang',
    @dob = '2006-04-18',
    @gender = 'Male',
    @citizen_id = '123456789',
    @address = N'456 Le Loi , Q1, TP.HCM';

-- Get customer id
DECLARE @khang_customer_id NCHAR(10);
SELECT @khang_customer_id = customer_id
FROM Customer
WHERE account_id = @khang_account;


-- Customer : Huan Ly
EXEC dbo.sp_account_register
    @username = 'huanlh2006',
    @email = 'huanlh2006@gmail.com',
    @phone_number = '0987654321',
    @password = 'hashed_password_here';

-- Get account id
DECLARE @huan_account BIGINT;
SELECT @huan_account = account_id
FROM Account
WHERE username = 'huanlh2006';

EXEC dbo.sp_otp_generate_otpcode 
    @account_id = @huan_account,
    @purpose = 'Register';

-- Get huan's OTP code
DECLARE @huan_otp_code NCHAR(6);
SELECT @huan_otp_code = otp_code
FROM OTP
WHERE account_id = @huan_account
    AND purpose = 'Register'
    AND verified = 0;

-- Verify OTP code
EXEC dbo.sp_otp_verify
    @account_id = @huan_account,
    @otp_code = @huan_otp_code,
    @purpose = 'Register';

-- Activate account
EXEC dbo.sp_account_activate
    @account_id = @huan_account;

-- Create customer profile
EXEC dbo.sp_create_customer_profile
    @account_id = @huan_account,
    @branch_id = @branch_id,
    @full_name = N'Ly Hoang Huan',
    @dob = '2006-01-15',
    @gender = 'Male',
    @citizen_id = '987654321',
    @address = N'789 Tran Hung Dao, Q1, TP.HCM';

--- Get customer id
DECLARE @huan_customer_id NCHAR(10);
SELECT @huan_customer_id = customer_id
FROM Customer
WHERE account_id = @huan_account;


/** 
    4. Employee Seed - Use to test sp_employee_create_profile
*/
INSERT INTO Account
    (username, email, phone_number, password_hash, role, created_at, status)
VALUES
    ('annt2006', 'annt2006@gmail.com', '345678901', 'hashed_password_here', 
        'Employee', GETDATE(), 'Active');

-- Get employee account id
DECLARE @employee_account BIGINT;
SELECT @employee_account = account_id
FROM Account
WHERE username = 'annt2006';

-- Create employee profile
EXEC dbo.sp_employee_create_profile
    @account_id = @employee_account,
    @branch_id = @branch_id,
    @full_name = N'Nguyen Tuan An',
    @dob = '2006-02-20',
    @gender = 'Male',
    @citizen_id = '1122334455',
    @address = N'321 Pham Ngu Lao, Q1, TP.HCM',
    @position = N'Teller';

/**
    5. Bank Account Seed - test sp_bank_account_create + sp_bank_transaction_deposit
*/
-- Create bank account for Khang
EXEC dbo.sp_bank_account_create
    @customer_id = @khang_customer_id,
    @account_type = 'Checking',
    @currency = 'VND';

-- Get bank account id
DECLARE @khang_bank_account_id BIGINT;
SELECT @khang_bank_account_id = bank_account_id
FROM BankingAccount
WHERE customer_id = @khang_customer_id;

-- Deposit money into bank account
EXEC dbo.sp_bank_transaction_deposit
    @bank_account_id = @khang_bank_account_id,
    @amount = 1000000,
    @description = N'Initial deposit';

-- Create bank account for Huan
EXEC dbo.sp_bank_account_create
    @customer_id = @huan_customer_id,
    @account_type = 'Checking',
    @currency = 'VND';

-- Get bank account id
DECLARE @huan_bank_account_id BIGINT;
SELECT @huan_bank_account_id = bank_account_id
FROM BankingAccount
WHERE customer_id = @huan_customer_id;

/** 
    6. Card Seed - test sp_card_create
*/
EXEC dbo.sp_card_create
    @bank_account_id = @khang_bank_account_id,
    @card_type = 'Debit';

/**
    7. Beneficiary Seed - test sp_beneficiary_create
    Khang adds Huan as a beneficiary
*/
EXEC dbo.sp_beneficiary_create
    @customer_id = @khang_customer_id,
    @beneficiary_name = N'Ly Hoang Huan',
    @bank_account_id = @huan_bank_account_id,
    @bank_name = N'Chi nhanh Quan 1';

/**
    8. Loan Officer Seed - Add employee to review loan application
*/
INSERT INTO Account
    (username, email, phone_number, password_hash, role, created_at, status)
VALUES
    ('haovn2006', 'haovn2006@gmail.com', '6789012345', 'hashed_password_here', 
        'Employee', GETDATE(), 'Active');

DECLARE @officer_account BIGINT;
SELECT @officer_account = account_id
FROM Account
WHERE username = 'haovn2006';

-- Create employee profile
EXEC dbo.sp_employee_create_profile
    @account_id = @officer_account,
    @branch_id = @branch_id,
    @full_name = N'Vuong Nhat Hao',
    @dob = '2006-05-30',
    @gender = 'Male',
    @citizen_id = '5566778899',
    @address = N'654 Le Lai, Q1, TP.HCM',
    @position = N'Loan Officer';

-- Get loan officer employee id
DECLARE @officer_employee_id NCHAR(10);
SELECT @officer_employee_id = employee_id
FROM Employee
WHERE account_id = @officer_account;

/** 
    9. Loan Seed - test sp_loan_apply + sp_loan_review + sp_loan_disburse
    Khang applies for a loan 20.000.000 VND and the duration is 12 months
    Approved by Loan Officer Vuong Nhat Hao then disbursed to Khang's bank account
*/
EXEC dbo.sp_loan_apply
    @customer_id = @khang_customer_id,
    @loan_type = 'Personal',
    @loan_amount = 20000000,
    @duration_months = 12,
    @annual_interest_rate = 12;

-- Get loan id
DECLARE @loan_id BIGINT;
SELECT @loan_id = loan_id
FROM Loan
WHERE customer_id = @khang_customer_id;

-- Review loan application
EXEC dbo.sp_loan_review
    @loan_id = @loan_id,
    @reviewer_id = @officer_employee_id,
    @decision = 'Approved';

-- Disburse loan to Khang's bank account
EXEC dbo.sp_loan_disburse
    @customer_id = @khang_customer_id,
    @loan_id = @loan_id,
    @bank_account_id = @khang_bank_account_id,
    @description = N'Loan disbursement for personal loan';

/**
    10. Saving Account Seed - test sp_saving_account_open
    Khang opens a saving account with initial deposit of 2.000.000 VND
        and the duration is 6 months
*/
EXEC dbo.sp_saving_account_open
    @customer_id = @khang_customer_id,
    @source_bank_account_id = @khang_bank_account_id,
    @deposit_amount = 2000000,
    @term_months = 6,
    @interest_rate = 5.5;

/**
    11. Notification Seed - test sp_notification_create
*/
EXEC dbo.sp_notification_create
    @account_id = @khang_account,
    @title = 'System',
    @message = N'Welcome to our banking system!';

/** 
    SUMMARY : print all result seed data 
*/
PRINT '-------------------- SEED DATA SUMMARY -------------------';
SELECT 'Branch' t , branch_id id , branch_name name 
FROM Branch
UNION ALL SELECT 'Customer', customer_id, full_name
FROM Customer
UNION ALL SELECT 'Employee', employee_id, full_name
FROM Employee;

PRINT '-------------------- BANK ACCOUNT SUMMARY -------------------';
SELECT bank_account_id, customer_id, balance, available_balance , status
FROM BankingAccount;

PRINT '-------------------- CARD SUMMARY -------------------';
SELECT card_id, bank_account_id, card_type, status
FROM Card;

PRINT '-------------------- BENEFICIARY SUMMARY -------------------';
SELECT beneficiary_id, customer_id, beneficiary_name
FROM Beneficiary;

PRINT '-------------------- LOAN SUMMARY -------------------';
SELECT loan_id, customer_id, amount, status, approved_by
FROM Loan;

PRINT '-------------------- SAVING ACCOUNT SUMMARY -------------------';
SELECT saving_id, source_bank_account_id, deposit_amount, status
FROM SavingAccount;

PRINT '-------------------- NOTIFICATION SUMMARY -------------------';
SELECT notification_id, account_id, title, message
FROM Notification;





