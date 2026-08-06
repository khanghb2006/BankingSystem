/*
======================================================
    LookUp Seed Data
    Author : Huynh Bao Khang
    Description : Sample data for demo and testing
======================================================
*/

USE BankingSystem
GO

-- Account Role
INSERT INTO AccountRole
    (role_name, description)
VALUES
    ('Admin', 'System Administrator'),
    ('Customer', 'Bank Customer'),
    ('Employee', 'Bank Employee');
GO

-- Account Status
INSERT INTO AccountStatus
    (status_name , description)
VALUES
    ('Active', 'Account is active'),
    ('Disabled', 'Account is disabled'),
    ('Locked', 'Account is locked');
GO

-- Customer Status 
INSERT INTO CustomerStatus
    (status_name, description)
VALUES
    ('Active', 'Customer is active'),
    ('Inactive', 'Customer is inactive');

-- Employee Position
INSERT INTO EmployeePosition
    (position_name, description)
VALUES
    ('Manager', 'Branch Manager'),
    ('Teller', 'Bank Teller'),
    ('Loan Officer', 'Loan Officer'),
    ('Customer Service', 'Customer Service Representative');
GO 

-- Employee Status
INSERT INTO EmployeeStatus
    (status_name, description)
VALUES
    ('Active', 'Employee is active'),
    ('On Leave', 'Employee is on leave'),
    ('Resigned', 'Employee has resigned');
GO

-- Branch Status
INSERT INTO BranchStatus
    (status_name, description)
VALUES
    ('Active', 'Branch is active'),
    ('Closed', 'Branch is closed');
GO

-- Banking Account Type
INSERT INTO BankingAccountType
    (type_name, description)
VALUES
    ('Savings', 'Savings Account'),
    ('Checking', 'Checking Account'),
    ('Business', 'Business Account');
GO

-- Banking Account Status
INSERT INTO BankingAccountStatus
    (status_name, description)
VALUES
    ('Active', 'Banking account is active'),
    ('Frozen', 'Banking account is frozen'),
    ('Closed', 'Banking account is closed');
GO

-- Currency
INSERT INTO Currency
    (currency_code, currency_name, symbol)
VALUES
    ('USD', 'United States Dollar', '$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound Sterling', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('VND', 'Vietnamese Dong', '₫');
GO

-- Card Type
INSERT INTO CardType
    (type_name, description)
VALUES
    ('Debit', 'Debit Card'),
    ('Credit', 'Credit Card');
GO

-- Card Status 
INSERT INTO CardStatus
    (status_name, description)
VALUES
    ('Active', 'Card is active'),
    ('Blocked', 'Card is blocked'),
    ('Expired', 'Card is expired');
GO

-- Transaction Type
INSERT INTO TransactionType
    (type_name, description)
VALUES
    ('Deposit', 'Deposit transaction'),
    ('Withdrawal', 'Withdrawal transaction'),
    ('Transfer', 'Transfer transaction'),
    ('Payment', 'Payment transaction');
GO

-- Transaction Status
INSERT INTO TransactionStatus
    (status_name, description)
VALUES
    ('Pending', 'Transaction is pending'),
    ('Successful', 'Transaction is successful'),
    ('Canceled', 'Transaction has been canceled'),
    ('Failed', 'Transaction has failed');
GO

-- Loan Type
INSERT INTO LoanType
    (type_name, description)
VALUES
    ('Personal', 'Personal Loan'),
    ('Home', 'Home Loan'),
    ('Auto', 'Auto Loan'),
    ('Education', 'Education Loan');
GO

-- Loan Status
INSERT INTO LoanStatus
    (status_name, description)
VALUES
    ('Pending', 'Loan application is pending'),
    ('Approved', 'Loan application is approved'),
    ('Rejected', 'Loan application is rejected'),
    ('Disbursed', 'Loan has been disbursed'),
    ('Closed', 'Loan has been closed');
GO

-- Saving Account Status
INSERT INTO SavingAccountStatus
    (status_name, description)
VALUES
    ('Active', 'Saving account is active'),
    ('Matured', 'Saving account has matured'),
    ('Closed', 'Saving account is closed');
GO

-- Notification Type
INSERT INTO NotificationType
    (type_name, description)
VALUES
    ('System', 'System Notification'),
    ('Transaction', 'Transaction Notification'),
    ('OTP', 'One-Time Password Notification');
GO

-- OTP Purpose
INSERT INTO OTPPurpose
    (purpose_name, description)
VALUES
    ('Login', 'OTP for login verification'),
    ('Register', 'OTP for account registration'),
    ('Transaction', 'OTP for transaction verification'),
    ('Verify Email', 'OTP for email verification'),
    ('PasswordReset', 'OTP for password reset');
GO

-- Login History Status
INSERT INTO LoginHistoryStatus
    (status_name, description)
VALUES
    ('Successful', 'Login attempt was successful'),
    ('Failed', 'Login attempt failed');