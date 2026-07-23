/*
=============================================
    Banking System Database Schema
    Author : Khang Huynh Bao
    Description : Create all database tables
*/

create database BankingSystem;
go

use BankingSystem;
go

create table Customer (
    customer_id nchar(10) primary key,
    first_name nvarchar(50) not null,
    last_name nvarchar(50) not null,
    gender varchar(10),
    dob date,
    phone_number nchar(10) not null,
    email nvarchar(50) not null,
    password_hash varchar(255) not null,
    citizen_id nchar(12) not null,
    address nvarchar(100),
    created_at datetime not null,
    updated_at datetime,
    status nvarchar(20) not null
);
go

create table Employee (
    employee_id nchar(10) primary key,
    first_name nvarchar(50) not null,
    last_name nvarchar(50) not null,
    email nvarchar(50) not null,
    phone_number nchar(10) not null,
    role nvarchar(30) not null,
    salary decimal(18, 2),
    hire_date date,
    branch_id nchar(10),
    status nvarchar(20) not null
);
go

create table Branch (
    branch_id nchar(10) primary key,
    branch_name nvarchar(50) not null,
    branch_code nchar(10) not null,
    address nvarchar(100),
    city nvarchar(50),
    phone_number nchar(10) not null,
    created_at datetime not null 
);
go

create table Account (
    account_id nchar(10) primary key,
    account_number nchar(20) not null,
    customer_id nchar(10),
    branch_id nchar(10),
    account_type nvarchar(20),
    currency nvarchar(10) not null,
    balance decimal(18, 2) not null,
    available_balance decimal(18, 2) not null,
    opened_at datetime,
    closed_at datetime,
    status nvarchar(20)
);
go

create table Card (
    card_id nchar(10) primary key,
    account_id nchar(10),
    card_number nchar(16) not null,
    card_type nvarchar(20),
    expired_at date,
    cvv_hash varchar(255),
    issued_at datetime,
    status nvarchar(20)
);
go

create table BankTransaction (
    transaction_id nchar(10) primary key,
    sender_account_id nchar(10),
    receiver_account_id nchar(10),
    amount decimal(18, 2) not null,
    fee decimal(18, 2),
    description nvarchar(255),
    transaction_type nvarchar(20),
    status nvarchar(20),
    created_at datetime 
);
go

create table Loan (
    loan_id nchar(10) primary key,
    customer_id nchar(10),
    amount decimal(18, 2),
    interest_rate decimal(18, 2),
    duration_months int,
    start_date date,
    end_date date,
    monthly_payment decimal(18, 2),
    remaining_balance decimal(18, 2),
    status nvarchar(20)
);
go

create table SavingAccount (
    saving_id nchar(10) primary key,
    deposit_account_id nchar(10),
    deposit_amount decimal(18, 2),
    interest_rate decimal(18, 2),
    term_months int,
    start_date date,
    maturity_date date,
    status nvarchar(20)
);
go

create table Beneficiary (
    beneficiary_id nchar(10) primary key,
    customer_id nchar(10),
    beneficiary_name nvarchar(50),
    beneficiary_account_number nchar(20),
    bank_name nvarchar(50),
    created_at datetime 
);
go

create table Notification (
    notification_id nchar(10) primary key,
    customer_id nchar(10),
    title nvarchar(100),
    content nvarchar(255),
    is_read bit,
    created_at datetime
);
go

create table OTP (
    otp_id nchar(10) primary key,
    customer_id nchar(10),
    otp_code nchar(6),
    purpose nvarchar(20),
    expired_at datetime,
    verified bit,
    created_at datetime
);
go

create table LoginHistory (
    login_id nchar(10) primary key,
    customer_id nchar(10),
    login_time datetime,
    ip_address varchar(50),
    device nvarchar(100),
    login_status nvarchar(20)
);
go