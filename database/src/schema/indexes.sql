/*
======================================================
    Banking System Database Indexes
    Author : Huynh Bao Khang
    Description : Secondary indexes for JOIN and search paths.

    Policy:
      - PRIMARY KEY and UNIQUE constraints already build an index;
        their columns are NOT repeated here.
      - Every FOREIGN KEY column is indexed (JOIN performance).
      - Columns filtered / sorted by the search procedures are indexed.
      - Skipped: bit flags, free-text columns only used with LIKE '%x%'.
======================================================
*/

USE BankingSystem;
GO

-- Account  (username / email / phone_number covered by UNIQUE constraints)
CREATE INDEX IX_Account_Status ON Account(status);
GO

-- Customer  (citizen_id covered by UNIQUE constraint)
CREATE INDEX IX_Customer_Account  ON Customer(account_id);
CREATE INDEX IX_Customer_Branch   ON Customer(branch_id);
CREATE INDEX IX_Customer_FullName ON Customer(full_name);
GO

-- Employee  (citizen_id covered by UNIQUE constraint)
CREATE INDEX IX_Employee_Account  ON Employee(account_id);
CREATE INDEX IX_Employee_Branch   ON Employee(branch_id);
CREATE INDEX IX_Employee_Position ON Employee(position);
CREATE INDEX IX_Employee_Status   ON Employee(status);
CREATE INDEX IX_Employee_FullName ON Employee(full_name);
GO

-- Branch
CREATE INDEX IX_Branch_Status     ON Branch(status);
CREATE INDEX IX_Branch_BranchName ON Branch(branch_name);
GO

-- Banking Account  (bank_account_number covered by UNIQUE constraint)
CREATE INDEX IX_BankingAccount_Customer ON BankingAccount(customer_id);
CREATE INDEX IX_BankingAccount_Type     ON BankingAccount(account_type);
CREATE INDEX IX_BankingAccount_Status   ON BankingAccount(status);
GO

-- Card  (card_number covered by UNIQUE constraint)
CREATE INDEX IX_Card_BankAccount ON Card(bank_account_id);
CREATE INDEX IX_Card_Type        ON Card(card_type);
CREATE INDEX IX_Card_Status      ON Card(status);
GO

-- Bank Transaction
CREATE INDEX IX_BankTransaction_FromAccount ON BankTransaction(from_bank_account_id, created_at);
CREATE INDEX IX_BankTransaction_ToAccount   ON BankTransaction(to_bank_account_id);
CREATE INDEX IX_BankTransaction_Type        ON BankTransaction(transaction_type);
CREATE INDEX IX_BankTransaction_Status      ON BankTransaction(status);
GO

-- Loan
CREATE INDEX IX_Loan_Customer   ON Loan(customer_id);
CREATE INDEX IX_Loan_ApprovedBy ON Loan(approved_by);
CREATE INDEX IX_Loan_Type       ON Loan(loan_type);
CREATE INDEX IX_Loan_Status     ON Loan(status);
CREATE INDEX IX_Loan_StartDate  ON Loan(start_date);
GO

-- Saving Account
CREATE INDEX IX_SavingAccount_Source    ON SavingAccount(source_bank_account_id);
CREATE INDEX IX_SavingAccount_Status    ON SavingAccount(status);
CREATE INDEX IX_SavingAccount_StartDate ON SavingAccount(start_date);
GO

-- Beneficiary
CREATE INDEX IX_Beneficiary_Customer    ON Beneficiary(customer_id);
CREATE INDEX IX_Beneficiary_BankAccount ON Beneficiary(bank_account_id);
GO

-- Notification
CREATE INDEX IX_Notification_Account ON Notification(account_id, created_at);
CREATE INDEX IX_Notification_Title   ON Notification(title);
GO

-- OTP
CREATE INDEX IX_OTP_Account ON OTP(account_id);
GO

-- Login History
CREATE INDEX IX_LoginHistory_Account ON LoginHistory(account_id, login_time);
CREATE INDEX IX_LoginHistory_Status  ON LoginHistory(login_status);
GO
