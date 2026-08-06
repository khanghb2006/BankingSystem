/*
======================================================
    LookUp Seed Data
    Author : Huynh Bao Khang
    Description : Sample data for demo and testing
======================================================
*/

use BankingSystem
go

-- Account Role
insert into AccountRole
    (role_name, description)
values
    ('Admin', 'System Administrator'),
    ('Customer', 'Bank Customer'),
    ('Employee', 'Bank Employee');
go

-- Account Status
insert into AccountStatus
    (status_name , description)
values
    ('Active', 'Account is active'),
    ('Disabled', 'Account is disabled'),
    ('Locked', 'Account is locked');
go

-- Customer Status 
insert into CustomerStatus
    (status_name, description)
values
    ('Active', 'Customer is active'),
    ('Inactive', 'Customer is inactive');

-- Employee Position
insert into EmployeePosition
    (position_name, description)
values
    ('Manager', 'Branch Manager'),
    ('Teller', 'Bank Teller'),
    ('Loan Officer', 'Loan Officer'),
    ('Customer Service', 'Customer Service Representative');
go 

-- Employee Status
insert into EmployeeStatus
    (status_name, description)
values
    ('Active', 'Employee is active'),
    ('On Leave', 'Employee is on leave'),
    ('Resigned', 'Employee has resigned');
go

-- Branch Status
insert into BranchStatus
    (status_name, description)
values
    ('Active', 'Branch is active'),
    ('Closed', 'Branch is closed');
go

-- Banking Account Type
insert into BankingAccountType
    (type_name, description)
values
    ('Savings', 'Savings Account'),
    ('Checking', 'Checking Account'),
    ('Business', 'Business Account');
go

-- Banking Account Status
insert into BankingAccountStatus
    (status_name, description)
values
    ('Active', 'Banking account is active'),
    ('Frozen', 'Banking account is frozen'),
    ('Closed', 'Banking account is closed');
go

-- Currency
insert into Currency
    (currency_code, currency_name, symbol)
values
    ('USD', 'United States Dollar', '$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound Sterling', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('VND', 'Vietnamese Dong', '₫');
go

-- Card Type
insert into CardType
    (type_name, description)
values
    ('Debit', 'Debit Card'),
    ('Credit', 'Credit Card');
go

-- Card Status 
insert into CardStatus
    (status_name, description)
values
    ('Active', 'Card is active'),
    ('Blocked', 'Card is blocked'),
    ('Expired', 'Card is expired');
go

-- Transaction Type
insert into TransactionType
    (type_name, description)
values
    ('Deposit', 'Deposit transaction'),
    ('Withdrawal', 'Withdrawal transaction'),
    ('Transfer', 'Transfer transaction'),
    ('Payment', 'Payment transaction');
go

-- Transaction Status
insert into TransactionStatus
    (status_name, description)
values
    ('Pending', 'Transaction is pending'),
    ('Successful', 'Transaction is successful'),
    ('Canceled', 'Transaction has been canceled'),
    ('Failed', 'Transaction has failed');
go

-- Loan Type
insert into LoanType
    (type_name, description)
values
    ('Personal', 'Personal Loan'),
    ('Home', 'Home Loan'),
    ('Auto', 'Auto Loan'),
    ('Education', 'Education Loan');
go

-- Loan Status
insert into LoanStatus
    (status_name, description)
values
    ('Pending', 'Loan application is pending'),
    ('Approved', 'Loan application is approved'),
    ('Rejected', 'Loan application is rejected'),
    ('Disbursed', 'Loan has been disbursed'),
    ('Closed', 'Loan has been closed');
go

-- Saving Account Status
insert into SavingAccountStatus
    (status_name, description)
values
    ('Active', 'Saving account is active'),
    ('Matured', 'Saving account has matured'),
    ('Closed', 'Saving account is closed');
go

-- Notification Type
insert into NotificationType
    (type_name, description)
values
    ('System', 'System Notification'),
    ('Transaction', 'Transaction Notification'),
    ('OTP', 'One-Time Password Notification');
go

-- OTP Purpose
insert into OTPPurpose
    (purpose_name, description)
values
    ('Login', 'OTP for login verification'),
    ('Register', 'OTP for account registration'),
    ('Transaction', 'OTP for transaction verification'),
    ('Verify Email', 'OTP for email verification'),
    ('PasswordReset', 'OTP for password reset');
go

-- Login History Status
insert into LoginHistoryStatus
    (status_name, description)
values
    ('Successful', 'Login attempt was successful'),
    ('Failed', 'Login attempt failed');