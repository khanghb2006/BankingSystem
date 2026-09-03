USE BankingSystem
GO

/*
======================================================
    Seed Data (via stored procedures)
    Author : Huynh Bao Khang
    Description : Sample data for demo and testing.
        Calls the sp_* procedures directly instead of
        raw INSERT, so running this script also acts as
        a smoke test for them.
======================================================
*/

SET NOCOUNT ON;

------------------------------------------------------
-- 1. Branch
------------------------------------------------------
EXEC sp_branch_create
    @branch_name = N'Chi nhánh Quận 1',
    @address = N'123 Nguyễn Huệ, Quận 1, TP.HCM',
    @phone_number = '0281234567';

DECLARE @branch_id NCHAR(10);
SELECT @branch_id = branch_id FROM Branch WHERE branch_name = N'Chi nhánh Quận 1';

------------------------------------------------------
-- 2. Account + Customer profile — Customer A
------------------------------------------------------
EXEC sp_account_register
    @username = 'khang_a',
    @email = 'khang_a@example.com',
    @phone_number = '0900000001',
    @password = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'Password123'), 2);

DECLARE @account_id_a BIGINT;
SELECT @account_id_a = account_id FROM Account WHERE username = 'khang_a';

-- Seed-only shortcut: skip the real OTP flow
-- (sp_otp_generate_otpcode -> sp_otp_verify -> sp_account_activate)
UPDATE Account SET status = 'Active' WHERE account_id = @account_id_a;

EXEC sp_create_customer_profile
    @account_id = @account_id_a,
    @branch_id = @branch_id,
    @full_name = N'Nguyễn Văn A',
    @dob = '1995-05-20',
    @gender = 'Male',
    @citizen_id = '079095000001',
    @address = N'12 Lê Lợi, Quận 1, TP.HCM';

DECLARE @customer_id_a NCHAR(10);
SELECT @customer_id_a = customer_id FROM Customer WHERE account_id = @account_id_a;

------------------------------------------------------
-- 3. Account + Customer profile — Customer B
------------------------------------------------------
EXEC sp_account_register
    @username = 'khang_b',
    @email = 'khang_b@example.com',
    @phone_number = '0900000002',
    @password = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'Password123'), 2);

DECLARE @account_id_b BIGINT;
SELECT @account_id_b = account_id FROM Account WHERE username = 'khang_b';

UPDATE Account SET status = 'Active' WHERE account_id = @account_id_b;

EXEC sp_create_customer_profile
    @account_id = @account_id_b,
    @branch_id = @branch_id,
    @full_name = N'Trần Thị B',
    @dob = '1998-11-02',
    @gender = 'Female',
    @citizen_id = '079098000002',
    @address = N'45 Hai Bà Trưng, Quận 1, TP.HCM';

DECLARE @customer_id_b NCHAR(10);
SELECT @customer_id_b = customer_id FROM Customer WHERE account_id = @account_id_b;

------------------------------------------------------
-- 4. Banking accounts
------------------------------------------------------
EXEC sp_bank_account_create
    @customer_id = @customer_id_a,
    @account_type = 'Checking',
    @currency = 'VND';

DECLARE @bank_account_id_a BIGINT;
SELECT @bank_account_id_a = bank_account_id 
FROM BankingAccount WHERE customer_id = @customer_id_a;

EXEC sp_bank_account_create
    @customer_id = @customer_id_b,
    @account_type = 'Checking',
    @currency = 'VND';

DECLARE @bank_account_id_b BIGINT;
SELECT @bank_account_id_b = bank_account_id 
FROM BankingAccount WHERE customer_id = @customer_id_b;

------------------------------------------------------
-- 5. Card for Customer A
------------------------------------------------------
EXEC sp_card_create
    @bank_account_id = @bank_account_id_a,
    @card_type = 'Debit';

------------------------------------------------------
-- 6. Beneficiary — A saves B
------------------------------------------------------
EXEC sp_beneficiary_create
    @customer_id = @customer_id_a,
    @beneficiary_name = N'Trần Thị B - bạn thân',
    @bank_account_id = @bank_account_id_b,
    @bank_name = N'BankingSystem';

------------------------------------------------------
-- 7. Transactions — deposit then transfer
------------------------------------------------------
EXEC sp_bank_transaction_deposit
    @bank_account_id = @bank_account_id_a,
    @amount = 5000000,
    @description = N'Nạp tiền mặt ban đầu';

EXEC sp_bank_transaction_transfer
    @from_bank_account_id = @bank_account_id_a,
    @to_bank_account_id = @bank_account_id_b,
    @amount = 1000000,
    @fee = 5000,
    @description = N'Chuyển tiền cho B';

------------------------------------------------------
-- 8. Sanity check
------------------------------------------------------
SELECT * FROM vw_Account;
SELECT * FROM vw_CardDetails;
SELECT * FROM vw_BeneficiaryDetails;
SELECT * FROM vw_TransactionSummary;