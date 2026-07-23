/*
======================================================
    LookUp Seed Data
    Author : Huỳnh Bảo Khang
    Description : Sample data for demo and testing
======================================================
*/

use BankingSystem
go

/* 
-----------------------------------------------------
    Login Status
-----------------------------------------------------
*/
insert into LoginStatus
    (status_name, description, is_active)
values
    ('Success', 'Login successful', 1),
    ('Failed', 'Login failed', 1),
    ('Locked', 'Account is locked', 1);
go
/* 
-----------------------------------------------------
    Account Type
-----------------------------------------------------
*/
insert into AccountType 
    (type_name, description, is_active)
values
    ('Savings', 'Savings Account', 1),
    ('Checking', 'Checking Account', 1);
go
/* 
-----------------------------------------------------
    Account Status
-----------------------------------------------------
*/
insert into AccountStatus 
    (status_name, description, is_active)
values
    ('Active', 'Active Account', 1),
    ('Frozen', 'Temporarily Frozen', 1),
    ('Closed', 'Closed Account', 1);
go
/* 
-----------------------------------------------------
    Transaction Type
-----------------------------------------------------
*/
insert into TransactionType 
    (type_name, description, is_active)
values
    ('Transfer', 'Money Transfer', 1),
    ('Deposit', 'Cash Deposit', 1),
    ('Withdraw', 'Cash Withdrawal', 1);
go
/* 
-----------------------------------------------------
    Transaction Status
-----------------------------------------------------
*/
insert into TransactionStatus 
    (status_name, description, is_active)
values
    ('Pending', 'Waiting', 1),
    ('Completed', 'Completed', 1),
    ('Failed', 'Failed', 1);
go
/* 
-----------------------------------------------------
    Card Type
-----------------------------------------------------
*/
insert into CardType 
    (type_name, description, is_active)
values
    ('Debit', 'Debit Card', 1),
    ('Credit', 'Credit Card', 1);
go
/* 
-----------------------------------------------------
    Card Status
-----------------------------------------------------
*/
insert into CardStatus 
    (status_name, description, is_active)
values
    ('Active', 'Card is active', 1),
    ('Blocked', 'Card is blocked', 1),
    ('Expired', 'Card expired', 1);
go
/* 
-----------------------------------------------------
    Customer Status
-----------------------------------------------------
*/
insert into CustomerStatus 
    (status_name, description, is_active)
values
    ('Active', 'Customer Active', 1),
    ('Inactive', 'Customer Inactive', 1),
    ('Locked', 'Customer Locked', 1);
go
/* 
-----------------------------------------------------
    Currency
-----------------------------------------------------
*/
insert into Currency 
    (currency_code, currency_name, symbol, is_active)
values
    ('VND', 'Vietnamese Dong', '₫', 1),
    ('USD', 'US Dollar', '$', 1),
    ('EUR', 'Euro', '€', 1),
    ('CNY','Chinese Yuan','¥',1);
go
/* 
-----------------------------------------------------
    Employee Role
-----------------------------------------------------
*/
insert into EmployeeRole 
    (role_name, description, is_active)
values
    ('Admin', 'System Administrator', 1),
    ('Manager', 'Branch Manager', 1),
    ('Teller', 'Bank Teller', 1),
    ('Customer Service', 'Customer Service', 1);
go
/* 
-----------------------------------------------------
    Employee Status
-----------------------------------------------------
*/
insert into EmployeeStatus 
    (status_name, description, is_active)
values
    ('Active', 'Working', 1),
    ('Inactive', 'Inactive', 1),
    ('Resigned', 'Resigned', 1);
go
/* 
-----------------------------------------------------
    Loan Status
-----------------------------------------------------
*/
insert into LoanStatus 
    (status_name, description, is_active)
values
    ('Pending', 'Waiting Approval', 1),
    ('Active', 'Loan Active', 1),
    ('Paid', 'Loan Fully Paid', 1),
    ('Overdue', 'Loan Overdue', 1),
    ('Rejected', 'Loan Rejected', 1);
go
/* 
-----------------------------------------------------
    Savings Status
-----------------------------------------------------
*/
insert into SavingStatus 
    (status_name, description, is_active)
values
    ('Active', 'Deposit Active', 1),
    ('Matured', 'Deposit Matured', 1),
    ('Closed', 'Deposit Closed', 1);
go

/*
-----------------------------------------------------
    OTP Type
-----------------------------------------------------
*/
insert into OTPType 
    (type_name, description, is_active)
values
    ('RESET_PASSWORD', 'OTP used for resetting customer password' , 1),
    ('VERIFY_EMAIL', 'OTP used for email verification', 1),
    ('TRANSFER', 'OTP used for money transfer confirmation', 1),
    ('CHANGE_PHONE', 'OTP used for changing phone number', 1),
    ('CHANGE_EMAIL', 'OTP used for changing email address', 1),
    ('ADD_BENEFICIARY', 'OTP used for adding beneficiary', 1);
go