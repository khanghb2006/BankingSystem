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

/* Customer */
alter table Customer
    add constraint FK_Customer_Status
        foreign key (status) references CustomerStatus(status_name);
go

/* Employee */
alter table Employee
    add constraint FK_Employee_Branch 
            foreign key (branch_id) references Branch(branch_id),

        constraint FK_Employee_Role
            foreign key (role) references EmployeeRole(role_name),

        constraint FK_Employee_Status
            foreign key (status) references EmployeeStatus(status_name);
go

/* Account */
alter table Account
    add constraint FK_Account_Customer
            foreign key (customer_id) references Customer(customer_id),

        constraint FK_Account_Branch
            foreign key (branch_id) references Branch(branch_id),

        constraint FK_Account_Type
            foreign key (account_type) references AccountType(type_name),
            
        constraint FK_Account_Status
            foreign key (status) references AccountStatus(status_name),

        constraint FK_Account_Currency
            foreign key (currency) references Currency(currency_code);
go

/* Card */
alter table Card
    add constraint FK_Card_Account 
            foreign key (account_id) references Account(account_id),

        constraint FK_Card_Type
            foreign key (card_type) references CardType(type_name),

        constraint FK_Card_Status
            foreign key (status) references CardStatus(status_name);
go

/* Bank Transaction */
alter table BankTransaction
    add constraint FK_BankTransaction_Sender
            foreign key (sender_account_id) references Account(account_id),

        constraint FK_BankTransaction_Receiver
            foreign key (receiver_account_id) references Account(account_id),

        constraint FK_BankTransaction_Type
            foreign key (transaction_type) references TransactionType(type_name),

        constraint FK_BankTransaction_Status
            foreign key (status) references TransactionStatus(status_name);
go

/* Loan */
alter table Loan
    add constraint FK_Loan_Customer
            foreign key (customer_id) references Customer(customer_id),

        constraint FK_Loan_Status
            foreign key (status) references LoanStatus(status_name);
go

/* SavingAccount */
alter table SavingAccount
    add constraint FK_SavingAccount_Account
            foreign key (deposit_account_id) references Account(account_id),

        constraint FK_SavingAccount_Status
            foreign key (status) references SavingStatus(status_name);
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
        foreign key (customer_id) references Customer(customer_id),
        constraint FK_OTP_Type
            foreign key (purpose) references OTPType(type_name);
go

/* Login History */
alter table LoginHistory
    add constraint FK_LoginHistory_Customer
            foreign key (customer_id) references Customer(customer_id),

        constraint FK_LoginHistory_Status
            foreign key (login_status) references LoginStatus(status_name);
go

/* 
--------------------------------------------------------
                Unique Constraints
--------------------------------------------------------
*/

/* Customer */
alter table Customer 
    add constraint UQ_Customer_Email unique(email);

alter table Customer
    add constraint UQ_Customer_Phone unique(phone_number);

alter table Customer
    add constraint UQ_Customer_Citizen unique(citizen_id);
go

/* Employee */
alter table Employee
    add constraint UQ_Employee_Email unique(email);

alter table Employee
    add constraint UQ_Employee_Phone unique(phone_number);
go

/* Branch */
alter table Branch
    add constraint UQ_Branch_Code unique(branch_code),

        constraint UQ_Branch_Phone unique(phone_number);
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
--------------------------------------------------------
                Check Constraints
--------------------------------------------------------
*/

/* Customer */
alter table Customer
    add constraint CK_Customer_Gender
        check (gender in ('Male', 'Female', 'Other'));
go

/* Employee */
alter table Employee
    add constraint CK_Employee_Salary
        check (salary >= 0);
go

/* Account */
alter table Account 
    add constraint CK_Account_Balance
            check (balance >= 0),

        constraint CK_Account_Available
            check (available_balance >= 0),

        constraint CK_Account_Balance_Logic
            check (available_balance <= balance);
go

/* Card */
alter table Card
    add constraint CK_Card_Expired
            check (expired_at > issued_at);
go

/* Transaction */
alter table BankTransaction 
    add constraint CK_BankTransaction_Amount
            check (amount > 0),

        constraint CK_BankTransaction_Fee
            check (fee >= 0);
go

/* Loan */
alter table Loan
    add constraint CK_Loan_Amount
            check (amount > 0),
        
        constraint CK_Loan_Duration
            check (duration_months > 0),
        
        constraint CK_Loan_MonthlyPayment
            check (monthly_payment >= 0),

        constraint CK_Loan_Interest
            check (interest_rate >= 0),

        constraint CK_Loan_Remaining
            check (remaining_balance >= 0),

        constraint CK_Loan_Dates
            check (end_date > start_date);
go

/* SavingAccount */
alter table SavingAccount 
    add constraint CK_SavingAccount_Deposit
            check (deposit_amount > 0),
        
        constraint CK_SavingAccount_Term
            check (term_months > 0),

        constraint CK_SavingAccount_Interest
            check (interest_rate >= 0),
    
        constraint CK_SavingAccount_Dates
            check (maturity_date > start_date);
go

/* OTP */
alter table OTP
    add constraint CK_OTP_Verified
            check (verified in (0 , 1)),

        constraint CK_OTP_Expired
            check (expired_at > created_at);
go

/* Notification */
alter table Notification
    add constraint CK_Notification_Read
        check (is_read in (0 , 1));
go