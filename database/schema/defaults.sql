/*
====================================================
    Banking System DEFAULT Values
    Author : Huynh Bao Khang
    Description : DEFAULT CONSTRAINTs
====================================================
*/

USE BankingSystem;
GO

-- Account
ALTER TABLE  Account ADD
    CONSTRAINT DF_Account_CreatedAt
        DEFAULT GETDATE() for created_at,
    CONSTRAINT DF_Account_Status
        DEFAULT 'Active' for status,
    CONSTRAINT DF_Account_UpdatedAt
        DEFAULT GETDATE() for updated_at;

-- Customer
ALTER TABLE  Customer ADD
    CONSTRAINT DF_Customer_CreatedAt
        DEFAULT GETDATE() for created_at,
    CONSTRAINT DF_Customer_UpdatedAt
        DEFAULT GETDATE() for updated_at,
    CONSTRAINT DF_Customer_Status
        DEFAULT 'Active' for status;
GO

-- Employee
ALTER TABLE  Employee ADD
    CONSTRAINT DF_Employee_HiredAt
        DEFAULT GETDATE() for hired_at,
    CONSTRAINT DF_Employee_CreatedAt
        DEFAULT GETDATE() for created_at,
    CONSTRAINT DF_Employee_UpdatedAt
        DEFAULT GETDATE() for updated_at,
    CONSTRAINT DF_Employee_Status
        DEFAULT 'Active' for status;
GO

-- Branch
ALTER TABLE  Branch ADD
    CONSTRAINT DF_Branch_Status
        DEFAULT 'Active' for status,
    CONSTRAINT DF_Branch_UpdatedAt
        DEFAULT GETDATE() for updated_at,
    CONSTRAINT DF_Branch_CreatedAt
        DEFAULT GETDATE() for created_at;
GO

-- Banking Account
ALTER TABLE  BankingAccount ADD
    CONSTRAINT DF_Account_Balance
        DEFAULT 0 for balance,
    CONSTRAINT DF_Account_AvailableBalance
        DEFAULT 0 for available_balance,
    CONSTRAINT DF_Account_OpenedAt
        DEFAULT GETDATE() for opened_at,
    CONSTRAINT DF_Account_Status
        DEFAULT 'Active' for status;
GO

-- Card
ALTER TABLE  Card ADD
    CONSTRAINT DF_Card_IssuedAt
        DEFAULT GETDATE() for issued_at,
    CONSTRAINT DF_Card_Status
        DEFAULT 'Active' for status;
GO

-- Bank Transaction
ALTER TABLE  BankTransaction ADD
    CONSTRAINT DF_BankTransaction_CreatedAt
        DEFAULT GETDATE() for created_at,
    CONSTRAINT DF_BankTransaction_Status
        DEFAULT 'Pending' for status,
    CONSTRAINT DF_BankTransaction_Fee
        DEFAULT 0 for fee;
GO

-- Loan
ALTER TABLE  Loan ADD
    CONSTRAINT DF_Loan_LoanType
        DEFAULT 'Personal' for loan_type,
    CONSTRAINT DF_Loan_Amount
        DEFAULT 0 for amount,
    CONSTRAINT DF_Loan_InterestRate
        DEFAULT 0 for interest_rate,
    CONSTRAINT DF_Loan_RemainingBalance
        DEFAULT 0 for remaining_balance,
    CONSTRAINT DF_Loan_StartDate
        DEFAULT GETDATE() for start_date,
    CONSTRAINT DF_Loan_DurationMonths
        DEFAULT 12 for duration_months,
    CONSTRAINT DF_Loan_Status
        DEFAULT 'Active' for status;
GO

-- Saving Account
ALTER TABLE  SavingAccount ADD 
    CONSTRAINT DF_SavingAccount_DepositAmount
        DEFAULT 0 for deposit_amount,
    CONSTRAINT DF_SavingAccount_InterestRate
        DEFAULT 0 for interest_rate,
    CONSTRAINT DF_SavingAccount_TermMonths
        DEFAULT 12 for term_months,
    CONSTRAINT DF_SavingAccount_StartDate
        DEFAULT GETDATE() for start_date,
    CONSTRAINT DF_SavingAccount_Status
        DEFAULT 'Active' for status;
GO

-- Beneficiary
ALTER TABLE  Beneficiary ADD
    CONSTRAINT DF_Beneficiary_CreatedAt
        DEFAULT GETDATE() for created_at;
GO

/* Notification */
ALTER TABLE  Notification ADD
    CONSTRAINT DF_Notification_Isread
        DEFAULT 0 for is_read,
    CONSTRAINT DF_Notification_CreatedAt
        DEFAULT GETDATE() for created_at;
GO

/* OTP */
ALTER TABLE  OTP ADD
    CONSTRAINT DF_OTP_CreatedAt
        DEFAULT GETDATE() for created_at,
    CONSTRAINT DF_OTP_Verified
            DEFAULT 0 for verified;
GO

/* Login History */
ALTER TABLE  LoginHistory ADD
    CONSTRAINT DF_LoginHistory_Time
        DEFAULT GETDATE() for login_time;