USE BankingSystem;
GO

-- ============================================================
-- 1. BRANCH — test sp_branch_create
-- ============================================================
EXEC dbo.sp_branch_create
    @branch_name  = N'Chi nhanh Quan 1',
    @address      = N'123 Nguyen Hue, Q1, TP.HCM',
    @phone_number = '0281234567';

DECLARE @branch_id NCHAR(10);
SELECT @branch_id = branch_id FROM Branch WHERE branch_name = N'Chi nhanh Quan 1';

-- ============================================================
-- 2. CUSTOMER ALICE — test sp_account_register, otp, activate, create_customer_profile
-- ============================================================
EXEC dbo.sp_account_register
    @username = 'alice', @email = N'alice@test.local',
    @phone_number = '0900000001', @password = 'hashed_password_1';

DECLARE @alice_acc BIGINT;
SELECT @alice_acc = account_id FROM Account WHERE username = 'alice';

EXEC dbo.sp_otp_generate_otpcode @account_id = @alice_acc, @purpose = 'Register';

DECLARE @alice_otp NCHAR(6);
SELECT @alice_otp = otp_code FROM OTP WHERE account_id = @alice_acc AND purpose = 'Register' AND verified = 0;

EXEC dbo.sp_otp_verify @account_id = @alice_acc, @otp_code = @alice_otp, @purpose = 'Register';
EXEC dbo.sp_account_activate @account_id = @alice_acc;

EXEC dbo.sp_create_customer_profile
    @account_id = @alice_acc, @branch_id = @branch_id,
    @full_name = N'Nguyen Thi Alice', @dob = '1995-05-20',
    @gender = 'Female', @citizen_id = '079095000001', @address = N'12 Le Loi, Q1';

DECLARE @alice_cus NCHAR(10);
SELECT @alice_cus = customer_id FROM Customer WHERE account_id = @alice_acc;

-- ============================================================
-- 3. CUSTOMER BOB — lặp lại luồng trên
-- ============================================================
EXEC dbo.sp_account_register
    @username = 'bob', @email = N'bob@test.local',
    @phone_number = '0900000002', @password = 'hashed_password_2';

DECLARE @bob_acc BIGINT;
SELECT @bob_acc = account_id FROM Account WHERE username = 'bob';

EXEC dbo.sp_otp_generate_otpcode @account_id = @bob_acc, @purpose = 'Register';

DECLARE @bob_otp NCHAR(6);
SELECT @bob_otp = otp_code FROM OTP WHERE account_id = @bob_acc AND purpose = 'Register' AND verified = 0;

EXEC dbo.sp_otp_verify @account_id = @bob_acc, @otp_code = @bob_otp, @purpose = 'Register';
EXEC dbo.sp_account_activate @account_id = @bob_acc;

EXEC dbo.sp_create_customer_profile
    @account_id = @bob_acc, @branch_id = @branch_id,
    @full_name = N'Tran Van Bob', @dob = '1993-03-15',
    @gender = 'Male', @citizen_id = '079093000002', @address = N'34 Hai Ba Trung, Q1';

DECLARE @bob_cus NCHAR(10);
SELECT @bob_cus = customer_id FROM Customer WHERE account_id = @bob_acc;

-- ============================================================
-- 4. EMPLOYEE — chưa có proc tự đăng ký, insert thẳng (admin tạo)
--    test sp_employee_create_profile
-- ============================================================
INSERT INTO Account (username, email, phone_number, password_hash, role, created_at, status)
VALUES ('teller01', N'teller01@bank.local', '0900000099', 'hashed_password_3', 'Employee', GETDATE(), 'Active');

DECLARE @emp_acc BIGINT = SCOPE_IDENTITY();

EXEC dbo.sp_employee_create_profile
    @account_id = @emp_acc, @branch_id = @branch_id,
    @full_name = N'Le Thi Teller', @dob = '1998-07-01',
    @gender = 'Female', @citizen_id = '079098000099',
    @address = N'56 Dong Khoi, Q1', @position = 'Teller';

-- ============================================================
-- 5. BANK ACCOUNT — test sp_bank_account_create + sp_bank_transaction_deposit
-- ============================================================
EXEC dbo.sp_bank_account_create @customer_id = @alice_cus, @account_type = 'Checking', @currency = 'VND';

DECLARE @alice_ba BIGINT;
SELECT @alice_ba = bank_account_id FROM BankingAccount WHERE customer_id = @alice_cus;

EXEC dbo.sp_bank_transaction_deposit @bank_account_id = @alice_ba, @amount = 5000000, @description = N'Nap tien ban dau';

EXEC dbo.sp_bank_account_create @customer_id = @bob_cus, @account_type = 'Checking', @currency = 'VND';

DECLARE @bob_ba BIGINT;
SELECT @bob_ba = bank_account_id FROM BankingAccount WHERE customer_id = @bob_cus;
-- Bob co y de 0d, dung de test "insufficient balance"

-- ============================================================
-- 6. CARD — test sp_card_create
-- ============================================================
EXEC dbo.sp_card_create @bank_account_id = @alice_ba, @card_type = 'Debit';

-- ============================================================
-- TỔNG KẾT — nhìn lại toàn bộ data vừa tạo
-- ============================================================
PRINT '=== KET QUA ===';
SELECT 'Branch' t, branch_id id, branch_name name FROM Branch
UNION ALL SELECT 'Customer', customer_id, full_name FROM Customer
UNION ALL SELECT 'Employee', employee_id, full_name FROM Employee;

SELECT bank_account_id, customer_id, balance, available_balance, status FROM BankingAccount;
SELECT card_id, bank_account_id, card_type, status FROM Card;