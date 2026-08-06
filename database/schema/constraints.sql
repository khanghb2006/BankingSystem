/*
======================================================
    Banking System Database CONSTRAINTs
    Author : Huynh Bao Khang
    Description : FOREIGN KEY, UNIQUE , CHECK CONSTRAINTS
======================================================
*/

USE BankingSystem;
GO

/* 
--------------------------------------------------------
                FOREIGN KEY CONSTRAINTS
--------------------------------------------------------
*/

-- Account
ALTER TABLE Account ADD
    CONSTRAINT FK_Account_Role FOREIGN KEY(role) REFERENCES AccountRole(role_name),
    CONSTRAINT FK_Account_Status FOREIGN KEY(status) REFERENCES AccountStatus(status_name);
GO

-- Customer
ALTER TABLE Customer ADD
    CONSTRAINT FK_Customer_Status FOREIGN KEY(status) REFERENCES CustomerStatus(status_name),
    CONSTRAINT FK_Customer_Account FOREIGN KEY(account_id) REFERENCES Account(account_id),
    CONSTRAINT FK_Customer_Branch FOREIGN KEY(branch_id) REFERENCES Branch(branch_id);
GO

-- Employee
ALTER TABLE Employee ADD
    CONSTRAINT FK_Employee_Account FOREIGN KEY(account_id) REFERENCES Account(account_id),
    CONSTRAINT FK_Employee_Branch FOREIGN KEY(branch_id) REFERENCES Branch(branch_id),
    CONSTRAINT FK_Employee_Position FOREIGN KEY(position) REFERENCES EmployeePosition(position_name),
    CONSTRAINT FK_Employee_Status FOREIGN KEY(status) REFERENCES EmployeeStatus(status_name);
GO

-- Branch
ALTER TABLE Branch ADD
    CONSTRAINT FK_Branch_Status FOREIGN KEY(status) REFERENCES BranchStatus(status_name);
GO

-- Banking Account
ALTER TABLE BankingAccount ADD
    CONSTRAINT FK_BankingAccount_Customer FOREIGN KEY(customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT FK_BankingAccount_Type FOREIGN KEY(account_type) REFERENCES BankingAccountType(type_name),
    CONSTRAINT FK_BankingAccount_Currency FOREIGN KEY(currency) REFERENCES Currency(currency_code),
    CONSTRAINT FK_BankingAccount_Status FOREIGN KEY(status) REFERENCES BankingAccountStatus(status_name);
GO

-- Card 
ALTER TABLE Card ADD
    CONSTRAINT FK_Card_BankingAccount FOREIGN KEY(bank_account_id) REFERENCES BankingAccount(bank_account_id),
    CONSTRAINT FK_Card_Type FOREIGN KEY(card_type) REFERENCES CardType(type_name),
    CONSTRAINT FK_Card_Status FOREIGN KEY(status) REFERENCES CardStatus(status_name);
GO

-- Transaction
ALTER TABLE BankTransaction ADD
    CONSTRAINT FK_BankTransaction_BankingAccount FOREIGN KEY(from_bank_account_id) REFERENCES BankingAccount(bank_account_id),
    CONSTRAINT FK_BankTransaction_BankingAccount_To FOREIGN KEY(to_bank_account_id) REFERENCES BankingAccount(bank_account_id),
    CONSTRAINT FK_BankTransaction_Type FOREIGN KEY(transaction_type) REFERENCES TransactionType(type_name),
    CONSTRAINT FK_BankTransaction_Status FOREIGN KEY(status) REFERENCES TransactionStatus(status_name);
GO

-- Loan 
ALTER TABLE Loan ADD
    CONSTRAINT FK_Loan_Customer FOREIGN KEY(customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT FK_Loan_ApproveBy FOREIGN KEY(approved_by) REFERENCES Employee(employee_id),
    CONSTRAINT FK_Loan_Type FOREIGN KEY(loan_type) REFERENCES LoanType(type_name),
    CONSTRAINT FK_Loan_Status FOREIGN KEY(status) REFERENCES LoanStatus(status_name);
GO

-- Saving Account
ALTER TABLE SavingAccount ADD
    CONSTRAINT FK_SavingAccount_Source FOREIGN KEY(source_bank_account) REFERENCES BankingAccount(bank_account_id),
    CONSTRAINT FK_SavingAccount_Status FOREIGN KEY(status) REFERENCES SavingAccountStatus(status_name);
GO

-- Beneficiary
ALTER TABLE Beneficiary ADD
    CONSTRAINT FK_Beneficiary_Customer FOREIGN KEY(customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT FK_Beneficiary_BankingAccount FOREIGN KEY(bank_account_id) REFERENCES BankingAccount(bank_account_id);
GO

-- Notification
ALTER TABLE Notification ADD
    CONSTRAINT FK_Notification_Title FOREIGN KEY(title) REFERENCES NotificationType(type_name),
    CONSTRAINT FK_Notification_Customer FOREIGN KEY(account_id) REFERENCES Account(account_id);
GO

-- OTP
ALTER TABLE OTP ADD
    CONSTRAINT FK_OTP_Purpose FOREIGN KEY(purpose) REFERENCES OTPPurpose(purpose_name),
    CONSTRAINT FK_OTP_Account FOREIGN KEY(account_id) REFERENCES Account(account_id);
GO

-- Login History
ALTER TABLE LoginHistory ADD
    CONSTRAINT FK_LoginHistory_Status FOREIGN KEY(status) REFERENCES LoginHistoryStatus(status_name),
    CONSTRAINT FK_LoginHistory_Account FOREIGN KEY(account_id) REFERENCES Account(account_id);
GO

/* 
--------------------------------------------------------
                UNIQUE CONSTRAINTS
--------------------------------------------------------
*/

-- Account
ALTER TABLE Account ADD
    CONSTRAINT UQ_Account_USErname UNIQUE(USErname),
    CONSTRAINT UQ_Account_Email UNIQUE(email),
    CONSTRAINT UQ_Account_PhoneNumber UNIQUE(phone_number);
GO

-- Customer
ALTER TABLE Customer ADD
    CONSTRAINT UQ_Customer_CitizenID UNIQUE(citizen_id);
GO

-- Employee
ALTER TABLE Employee ADD
    CONSTRAINT UQ_Employee_CitizenID UNIQUE(citizen_id);
GO

-- BankingAccount
ALTER TABLE BankingAccount ADD
    CONSTRAINT UQ_BankingAccount_AccountNumber UNIQUE(bank_account_number);
GO

-- Card 
ALTER TABLE Card ADD
    CONSTRAINT UQ_Card_CardNumber UNIQUE(card_number);
GO

/* 
--------------------------------------------------------
                CHECK CONSTRAINTS
--------------------------------------------------------
*/

-- Customer 
ALTER TABLE Customer ADD
    CONSTRAINT CK_Customer_Gender 
        CHECK(gender in ('Male', 'Female' , 'Other'));
GO

-- Employee
ALTER TABLE Employee ADD
    CONSTRAINT CK_Employee_Gender 
        CHECK(gender in ('Male', 'Female' , 'Other'));
GO

-- Banking Account
ALTER TABLE BankingAccount ADD
    CONSTRAINT CK_BankingAccount_Balance 
        CHECK(
            balance >= 0
            AND available_balance >= 0
            AND available_balance <= balance
        );
GO

-- Bank Transaction
ALTER TABLE BankTransaction ADD
    CONSTRAINT CK_BankTransaction_Amount 
        CHECK(amount > 0);
GO

-- Loan
ALTER TABLE Loan ADD
    CONSTRAINT CK_Loan_Amount 
        CHECK(amount > 0),
    CONSTRAINT CK_Loan_InterestRate
        CHECK(interest_rate >= 0),
    CONSTRAINT CK_Loan_Remaining
        CHECK(remaining_balance >= 0);
GO

-- Saving Account
ALTER TABLE SavingAccount ADD
    CONSTRAINT CK_SavingAccount_InterestRate 
        CHECK(interest_rate >= 0),
    CONSTRAINT CK_SavingAccount_Amount 
        CHECK(deposit_amount > 0);
GO