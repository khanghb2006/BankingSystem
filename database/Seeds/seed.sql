/*
======================================================
    Seed Data
    Author : Huỳnh Bảo Khang
    Description : Sample data for demo and testing
======================================================
*/

use BankingSystem
go

/*
-----------------------------------------------------
    Branch
-----------------------------------------------------
*/
insert into Branch 
    (branch_id , branch_name , branch_code , address , city , phone_number , created_at)
values
    ('BR00000001', N'Head Office', 'HCM001', N'1 Nguyễn Huệ', N'Hồ Chí Minh', '0281111111', getdate()),
    ('BR00000002', N'Chi nhánh Hà Nội', 'HN001', N'10 Ba Đình', N'Hà Nội', '0242222222', getdate());
go

/*
-----------------------------------------------------
    Customer
-----------------------------------------------------
*/
insert into Customer
    (customer_id, first_name, last_name, gender, dob, phone_number, email, password_hash,
        citizen_id, address, created_at, updated_at, status)
values
    ('CIF0000001',N'Huỳnh Bảo',N'Khang','Male','2006-04-18', '0901234567','khang@gmail.com',
        '123456', '079204012345', N'Hồ Chí Minh', getdate(),NULL,'Active'),
    ('CIF0000002',N'Nguyễn Tuấn',N'An','Male','2000-02-10', '0901234568','an@gmail.com',
        '123456', '079204012346', N'Hà Nội', getdate(),NULL,'Active'),
    ('CIF0000003',N'Phú Thảo',N'Nguyên','Female','2002-07-20', '0901234569','tng@gmail.com',
        '123456', '079204012347', N'Đà Nẵng', getdate(),NULL,'Active');
go

/*
-----------------------------------------------------
    Account
-----------------------------------------------------
*/
insert into Account
    (account_id,account_number,customer_id,branch_id, account_type,currency,balance,
        available_balance, opened_at,closed_at,status)
values
    ('AC00000001', '11111111111111111111', 'CIF0000001', 'BR00000001', 'Savings',
        'VND', 5000000, 5000000, getdate(), NULL, 'Active'),
    ('AC00000002', '22222222222222222222', 'CIF0000002', 'BR00000002', 'Savings',
        'VND', 12000000, 12000000, getdate(), NULL,'Active'),
    ('AC00000003', '33333333333333333333', 'CIF0000003', 'BR00000001', 'Checking',
        'VND', 8000000, 8000000, getdate(), NULL, 'Active');
go

/*
-----------------------------------------------------
    Card
-----------------------------------------------------
*/
insert into Card
    (card_id, account_id, card_number, card_type, expired_at, cvv_hash, issued_at, status)
values
    ('CA00000001', 'AC00000001', '1111222233334444', 'Debit', '2030-12-31', '123',
        getdate(), 'Active'),
    ('CA00000002', 'AC00000002', '5555666677778888', 'Debit', '2030-12-31', '123',
        getdate(), 'Active');
go

/*
-----------------------------------------------------
    Loan
-----------------------------------------------------
*/
insert into Loan
    (loan_id, customer_id, amount, interest_rate, duration_months, start_date, 
        end_date, monthly_payment, remaining_balance, status)
values
    ('LO00000001', 'CIF0000001', 100000000, 7.5, 24, getdate(),
        dateadd(MONTH,24,getdate()), 4500000, 90000000, 'Active');
go

/*
-----------------------------------------------------
    Savings Account
-----------------------------------------------------
*/
insert into SavingAccount
    (saving_id, deposit_account_id, deposit_amount, interest_rate, term_months, 
        start_date, maturity_date, status)
values
    ('SA00000001', 'AC00000001', 50000000, 5.5, 12,
        getdate(), dateadd(MONTH,12,getdate()), 'Active');
go

/*
-----------------------------------------------------
    Beneficiary
-----------------------------------------------------
*/
insert into Beneficiary
    (beneficiary_id, customer_id, beneficiary_name, beneficiary_account_number, 
        bank_name, created_at)
values
    ('BE00000001', 'CIF0000001', N'Nguyễn Tuấn An', '22222222222222222222',
        'BankingSystem', getdate()),
    ('BE00000002', 'CIF0000002', N'Huỳnh Bảo Khang', '11111111111111111111',
        'BankingSystem', getdate());
go

/*
-----------------------------------------------------
    Notification
-----------------------------------------------------
*/
insert into Notification
    (notification_id, customer_id, title, content, is_read, created_at)
values
    ('NO00000001', 'CIF0000001', N'Welcome', N'Welcome to Banking System.',
        0, getdate()),
    ('NO00000002', 'CIF0000002', N'Account Created', N'Your account has been created.',
        0, getdate());
go

/*
-----------------------------------------------------
    OTP
-----------------------------------------------------
*/
insert into OTP
    (otp_id, customer_id, otp_code, purpose, expired_at, verified, created_at)
values
    ('OT00000001', 'CIF0000001', '123456', 'RESET_PASSWORD', dateadd(MINUTE,5,getdate()),
        0, getdate());
go

/*
-----------------------------------------------------
    Login History
-----------------------------------------------------
*/
insert into LoginHistory
    (login_id, customer_id, login_time, ip_address, device, login_status)
values
    ('LG00000001', 'CIF0000001', getdate(), '127.0.0.1', 'Chrome Windows', 'Success');
go

/*
-----------------------------------------------------
    Bank Transaction
-----------------------------------------------------
*/
insert into BankTransaction
    (transaction_id, sender_account_id, receiver_account_id, amount, fee, 
        transaction_type, description, status, created_at)
values
    ('TR00000001', 'AC00000001', 'AC00000002', 500000, 0, N'Transfer',
        'Transfer', 'Completed', getdate()),
    ('TR00000002', 'AC00000002', 'AC00000003', 1000000, 0, N'Transfer',
        'Transfer', 'Completed', getdate());
go



