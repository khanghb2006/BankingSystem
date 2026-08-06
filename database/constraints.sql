/*
======================================================
    Banking System Database Constraints
    Author : Huynh Bao Khang
    Description : Foreign key, unique , check constraints 
======================================================
*/

use BankingSystem;
go

/* 
--------------------------------------------------------
                Foreign Key Constraints
--------------------------------------------------------
*/

-- Account
alter table Account add
    constraint FK_Account_Role foreign key(role) references AccountRole(role_name),
    constraint FK_Account_Status foreign key(status) references AccountStatus(status_name);
go

-- Customer
alter table Customer add
    constraint FK_Customer_Account foreign key(account_id) references Account(account_id),
    constraint FK_Customer_Branch foreign key(branch_id) references Branch(branch_id);
go

-- Employee
alter table Employee add
    constraint FK_Employee_Account foreign key(account_id) references Account(account_id),
    constraint FK_Employee_Branch foreign key(branch_id) references Branch(branch_id),
    constraint FK_Employee_Position foreign key(position) references EmployeePosition(position_name),
    constraint FK_Employee_Status foreign key(status) references EmployeeStatus(status_name);
go

-- Branch
alter table Branch add
    constraint FK_Branch_Status foreign key(status) references BranchStatus(status_name);
go

-- Banking Account
alter table BankingAccount add
    constraint FK_BankingAccount_Customer foreign key(customer_id) references Customer(customer_id),
    constraint FK_BankingAccount_Type foreign key(account_type) references BankingAccountType(type_name),
    constraint FK_BankingAccount_Currency foreign key(currency) references Currency(currency_code),
    constraint FK_BankingAccount_Status foreign key(status) references BankingAccountStatus(status_name);
go

-- Card 
alter table Card add
    constraint FK_Card_BankingAccount foreign key(bank_account_id) references BankingAccount(bank_account_id),
    constraint FK_Card_Type foreign key(card_type) references CardType(type_name),
    constraint FK_Card_Status foreign key(status) references CardStatus(status_name);
go

-- Transaction
alter table BankTransaction add
    constraint FK_BankTransaction_BankingAccount foreign key(from_bank_account_id) references BankingAccount(bank_account_id),
    constraint FK_BankTransaction_BankingAccount_To foreign key(to_bank_account_id) references BankingAccount(bank_account_id),
    constraint FK_BankTransaction_Type foreign key(transaction_type) references TransactionType(type_name),
    constraint FK_BankTransaction_Status foreign key(status) references TransactionStatus(status_name);
go

-- Loan 
alter table Loan add
    constraint FK_Loan_Customer foreign key(customer_id) references Customer(customer_id),
    constraint FK_Loan_ApproveBy foreign key(approved_by) references Employee(employee_id),
    constraint FK_Loan_Type foreign key(loan_type) references LoanType(type_name),
    constraint FK_Loan_Status foreign key(status) references LoanStatus(status_name);
go

-- Saving Account
alter table SavingAccount add
    constraint FK_SavingAccount_Source foreign key(source_bank_account) references BankingAccount(bank_account_id),
    constraint FK_SavingAccount_Status foreign key(status) references SavingAccountStatus(status_name);
go

-- Beneficiary
alter table Beneficiary add
    constraint FK_Beneficiary_Customer foreign key(customer_id) references Customer(customer_id),
    constraint FK_Beneficiary_BankingAccount foreign key(bank_account_id) references BankingAccount(bank_account_id);
go

-- Notification
alter table Notification add
    constraint FK_Notification_Title foreign key(title) references NotificationType(type_name),
    constraint FK_Notification_Customer foreign key(account_id) references Account(account_id);
go

-- OTP
alter table OTP add
    constraint FK_OTP_Purpose foreign key(purpose) references OTPPurpose(purpose_name),
    constraint FK_OTP_Account foreign key(account_id) references Account(account_id);
go

-- Login History
alter table LoginHistory add
    constraint FK_LoginHistory_Status foreign key(status) references LoginHistoryStatus(status_name),
    constraint FK_LoginHistory_Account foreign key(account_id) references Account(account_id);
go

/* 
--------------------------------------------------------
                Unique Constraints
--------------------------------------------------------
*/

-- Account
alter table Account add
    constraint UQ_Account_Username unique(username),
    constraint UQ_Account_Email unique(email),
    constraint UQ_Account_PhoneNumber unique(phone_number);
go

-- Customer
alter table Customer add
    constraint UQ_Customer_CitizenID unique(citizen_id);
go

-- Employee
alter table Employee add
    constraint UQ_Employee_CitizenID unique(citizen_id);
go

-- BankingAccount
alter table BankingAccount add
    constraint UQ_BankingAccount_AccountNumber unique(bank_account_number);
go

-- Card 
alter table Card add
    constraint UQ_Card_CardNumber unique(card_number);
go

/* 
--------------------------------------------------------
                Check Constraints
--------------------------------------------------------
*/

-- Customer 
alter table Customer add
    constraint CK_Customer_Gender 
        check(gender in ('Male', 'Female' , 'Other'));
go

-- Employee
alter table Employee add
    constraint CK_Employee_Gender 
        check(gender in ('Male', 'Female' , 'Other'));
go

-- Banking Account
alter table BankingAccount add
    constraint CK_BankingAccount_Balance 
        check(
            balance >= 0
            and available_balance >= 0
            and available_balance <= balance
        );
go

-- Bank Transaction
alter table BankTransaction add
    constraint CK_BankTransaction_Amount 
        check(amount > 0);
go

-- Loan
alter table Loan add
    constraint CK_Loan_Amount 
        check(amount > 0),
    constraint CK_Loan_InterestRate
        check(interest_rate >= 0),
    constraint CK_Loan_Remaining
        check(remaining_balance >= 0);
go

-- Saving Account
alter table SavingAccount add
    constraint CK_SavingAccount_InterestRate 
        check(interest_rate >= 0),
    constraint CK_SavingAccount_Amount 
        check(deposit_amount > 0);
go