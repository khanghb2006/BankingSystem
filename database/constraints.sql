/*
======================================================
    Banking System Database Constraints
    Author : Khang Huynh Bao
    Description : Foreign key, unique , check constraints 
======================================================
*/

use BankingSystem;
go

/* 
    ========================================================
                Foreign Key Constraints
    ========================================================
*/

/* Employee */
alter table Employee
    add constraint FK_Employee_Branch 
    foreign key (branch_id) references Branch(branch_id);
go

/* Account */
alter table Account
    add constraint FK_Account_Customer
        foreign key (customer_id) references Customer(customer_id);
    add constraint FK_Account_Branch
        foreign key (branch_id) references Branch(branch_id);
go

/* Card */
alter table Card
    add constraint FK_Card_Account 
    foreign key (account_id) references Account(account_id);
go

/* Transaction */
alter table BankTransaction
    add constraint FK_BankTransaction_Sender
        foreign key (sender_account_id) references Account(account_id);
    add constraint FK_BankTransaction_Receiver
        foreign key (receiver_account_id) references Account(account_id);
go

/* Loan */
alter table Loan
    add constraint FK_Loan_Customer
    foreign key (customer_id) references Customer(customer_id);
go

/* SavingAccount */
alter table SavingAccount
    add constraint FK_SavingAccount_Customer
    foreign key (deposit_account_id) references Account(account_id);
go

/* Beneficiary */
alter table Beneficiary
    add constraint FK_Beneficiary_Customer
    foreign key (customer_id) references Customer(customer_id);
go

/* Notification */
alter table Notification
    add constraint FK_Notification_Customer
    foreign key (customer_id) references Customer(customer_id);
go

/* OTP */
alter table OTP
    add constraint FK_OTP_Customer
    foreign key (customer_id) references Customer(customer_id);
go

/* Login History */
alter table LoginHistory
    add constraint FK_LoginHistory_Customer
    foreign key (customer_id) references Customer(customer_id);
go

/* 
    ========================================================
                Unique Constraints
    ========================================================
*/

/* Customer */
alter table Customer 
    add constraint UQ_Customer_Email unique(email);
    add constraint UQ_Customer_Phone unique(phone_number);
    add constraint UQ_Customer_Citizen unique(citizen_id);
go

/* Employee */
alter table Employee
    add constraint UQ_Employee_Email unique(email);
    add constraint UQ_Employee_Phone unique(phone_number);
go

/* Branch */
alter table Branch
    add constraint UQ_Branch_Code unique(branch_code);
    add constraint UQ_Branch_Phone unique(phone_number);
go

/* Account */
alter table Account
    add constraint UQ_Account_Number unique(account_number);
go

/* Card */
alter table Card
    add constraint UQ_Card_Number unique(card_number);
go

/* 
    =======================================================
                Check Constraints
    =======================================================
*/

/* Customer */
alter table Customer
    add constraint CK_Customer_Gender
        check (gender in ('Male', 'Female', 'Other'));
    add constraint CK_Customer_Status
        check (status in ('Active', 'Inactive', 'Locked'));
go

/* Employee */
alter table Employee
    add constraint CK_Employee_Status
        check (status in ('Active' , 'Inactive'));
    add constraint CK_Employee_Salary
        check (salary >= 0);
go

/* Account */
alter table Account 
    add constraint CK_Account_Type
        check (account_type in ('Checking' , 'Savings'));
    add constraint CK_Account_Status
        check (status in ('Active' , 'Inactive' , 'Closed'));
    add constraint CK_Account_Balance
        check (balance >= 0);
    add constraint CK_Account_Available
        check (available_balance >= 0);
    add constraint CK_Account_Balance_Logic
        check (available_balance <= balance);
go

/* Card */
alter table Card
    add constraint CK_Card_Type
        check (card_type in ('Debit' , 'Credit'));
    add constraint CK_Card_Status
        check (status in ('Active' , 'Expired' , 'Blocked'));
    add constraint CK_Card_Expired
        check (expired_at > issued_at);
go

/* Transaction */
alter table BankTransaction 
    add constraint CK_BankTransaction_Amount
        check (amount > 0);
    add constraint CK_BankTransaction_Fee
        check (fee >= 0);
    add constraint CK_BankTransaction_Type 
        check (transaction_type in ('Deposit' , 'Withdrawal' , 'Transfer'));
    add constraint CK_BankTransaction_Status
        check (status in ('Pending' , 'Success' , 'Failed'));
go

/* Loan */
alter table Loan
    add constraint CK_Loan_Amount
        check (amount > 0);
    add constraint CK_Loan_Interest
        check (interest_rate >= 0);
    add constraint CK_Loan_Status
        check (status in ('Active' , 'Paid' , 'Overdue'));
    add constraint CK_Loan_Remaining
        check (remaining_balance >= 0);
    add constraint CK_Loan_Dates
        check (end_date > start_date);
go

/* SavingAccount */
alter table SavingAccount 
    add constraint CK_SavingAccount_Deposit
        check (deposit_amount > 0);
    add constraint CK_SavingAccount_Interest
        check (interest_rate >= 0);
    add constraint CK_SavingAccount_Status
        check (status in ('Active' , 'Matured' , 'Closed'));
    add constraint CK_SavingAccount_Dates
        check (maturity_date > start_date);
go

/* OTP */
alter table OTP
    add constraint CK_OTP_Verified
        check (verified in (0 , 1));
    add constraint CK_OTP_Expired
        check (expired_at > created_at);
go

/* Notification */
alter table Notification
    add constraint CK_Notification_Read
        check (is_read in (0 , 1));