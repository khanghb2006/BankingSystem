/* 
========================================
    Banking System Lookup Tables
    Author : Huynh Bao Khang
    Description : Lookup Tables for Banking System
========================================
*/

use BankingSystem
go

-- Account Role
create table AccountRole (
    role_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Account Status
create table AccountStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Customer Status
create table CustomerStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);

-- Employee Position
create table EmployeePosition (
    position_name varchar(50) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Employee Status
create table EmployeeStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Branch Status
create table BranchStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Banking Account Type
create table BankingAccountType (
    type_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

--Banking Account Status
create table BankingAccountStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Currency 
create table Currency (
    currency_code varchar(10) primary key,
    currency_name nvarchar(50),
    symbol nvarchar(10),
    is_active bit not null default 1
);
go 

-- Card Type
create table CardType (
    type_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Card Status
create table CardStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Transaction Type
create table TransactionType (
    type_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Transaction Status
create table TransactionStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Loan Type 
create table LoanType (
    type_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Loan Status
create table LoanStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Saving Account Status
create table SavingAccountStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Notification Type
create table NotificationType (
    type_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- OTP Purpose
create table OTPPurpose (
    purpose_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);
go

-- Login History Status
create table LoginHistoryStatus (
    status_name varchar(20) primary key,
    description nvarchar(100),
    is_active bit not null default 1
);