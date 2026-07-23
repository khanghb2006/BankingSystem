/* 
========================================
    Banking System Lookup Tables
    Author : Huynh Bao Khang
    Description : Master Lookup Tables for Banking System
========================================
*/

use BankingSystem
go


/*
------------------------------------------------------
    Login History Lookup
------------------------------------------------------
*/
create table LoginStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/*
------------------------------------------------------
    Customer Status Lookup
------------------------------------------------------
*/
create table CustomerStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/*
------------------------------------------------------
    Employee Role Lookup
------------------------------------------------------
*/
create table EmployeeRole (
    role_name nvarchar(30) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go 

/* 
------------------------------------------------------
    Employee Status Lookup
------------------------------------------------------
*/
create table EmployeeStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/* 
------------------------------------------------------
    Account Type Lookup
------------------------------------------------------
*/
create table AccountType (
    type_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/*
------------------------------------------------------
    Account Status Lookup
------------------------------------------------------
*/
create table AccountStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/* 
------------------------------------------------------
    Currency Lookup
------------------------------------------------------
*/
create table Currency (
    currency_code nvarchar(10) primary key,
    currency_name nvarchar(50),
    symbol nvarchar(10),
    is_active bit not null default 1
);
go

/*
------------------------------------------------------
    Card Type Lookup
------------------------------------------------------
*/
create table CardType (
    type_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go 

/* 
------------------------------------------------------
    Card Status Lookup
------------------------------------------------------
*/ 
create table CardStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/*
------------------------------------------------------
    Transaction Type Lookup
------------------------------------------------------
*/
create table TransactionType (
    type_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/* 
------------------------------------------------------
    Transaction Status Lookup
------------------------------------------------------
*/
create table TransactionStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/* 
------------------------------------------------------
    Loan Status Lookup 
------------------------------------------------------
*/
create table LoanStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/* 
------------------------------------------------------
    Saving Account Status Lookup
------------------------------------------------------
*/
create table SavingStatus (
    status_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

/*
------------------------------------------------------
    OTP Type Lookup
------------------------------------------------------
*/

create table OTPType (
    type_name nvarchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go