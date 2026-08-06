/*
=============================================
    Banking System Database Schema
    Author : Huynh Bao Khang
    Description : Create all database tables
=============================================
*/

create database BankingSystem;
go

use BankingSystem;
go

create table Account (
    account_id bigint identity(1,1) primary key,

    username varchar(50) not null,
    email nvarchar(100) not null,
    phone_number varchar(20) not null,
    password_hash varchar(255) not null,
    role varchar(20) not null,

    created_at datetime not null,
    updated_at datetime,
    status varchar(20) not null
);
go

create table Customer (
    customer_id nchar(10) primary key,
    account_id bigint not null,
    branch_id bigint not null,

    full_name nvarchar(100) not null,
    dob date not null,
    gender varchar(10) not null,
    citizen_id varchar(20) not null,
    address nvarchar(255) not null,
    
    created_at datetime not null,
    updated_at datetime
);
go

create table Employee (
    employee_id nchar(10) primary key,
    account_id bigint not null,
    branch_id bigint not null,

    position varchar(50) not null,
    full_name nvarchar(100) not null,
    dob date not null,
    gender varchar(10) not null,
    citizen_id varchar(20) not null,
    address nvarchar(255) not null,

    status nvarchar(20) not null,
    hired_at datetime not null,
    created_at datetime not null,
    updated_at datetime
);
go

create table Branch (
    branch_id nchar(10) primary key,
    branch_name nvarchar(100) not null,
    address nvarchar(100),
    phone_number varchar(20) not null,

    created_at datetime not null,
    updated_at datetime,
    status nvarchar(20) not null
);
go

create table BankingAccount (
    bank_account_id bigint identity(1,1) primary key,
    customer_id nchar(10) not null,

    bank_account_number nchar(20) not null,
    balance decimal(18, 2) not null,
    account_type nvarchar(20) not null,
    currency nvarchar(10) not null,
    available_balance decimal(18, 2) not null,

    opened_at datetime not null,
    closed_at datetime,
    status nvarchar(20) not null
);
go

create table Card (
    card_id bigint identity(1 , 1) primary key,
    bank_account_id bigint not null,

    card_number varchar(20) not null,
    card_type nvarchar(20) not null,
    expired_at date,
    cvv_hash varchar(255) not null,
    issued_at datetime not null,
    status nvarchar(20) not null
);
go

create table BankTransaction (
    transaction_id bigint identity(1 , 1) primary key,
    from_bank_account_id bigint not null,
    to_bank_account_id bigint not null,

    transaction_type nvarchar(20) not null,
    amount decimal(18, 2) not null,
    description nvarchar(255),
    created_at datetime not null,
    status nvarchar(20) not null
);
go

create table Loan (
    loan_id bigint identity(1 , 1) primary key,
    customer_id nchar(10) not null,

    loan_type varchar(20) not null,
    amount decimal(18, 2) not null,
    interest_rate decimal(18, 2) not null,
    remaining_balance decimal(18, 2) not null,
    duration_months int not null,
    start_date date not null,
    end_date date not null,
    monthly_payment decimal(18, 2) not null,

    approved_by nchar(10) not null,
    status nvarchar(20) not null
);
go

create table SavingAccount (
    saving_id bigint identity(1 , 1) primary key,
    source_bank_account_id bigint not null,
    deposit_amount decimal(18, 2) not null,
    interest_rate decimal(18, 2) not null,
    term_months int not null,
    start_date date not null,
    maturity_date date not null,
    status nvarchar(20) not null
);
go

create table Beneficiary (
    beneficiary_id bigint identity(1 , 1) primary key,
    customer_id nchar(10) not null,
    beneficiary_name nvarchar(50) not null,
    bank_account_number nchar(20) not null,
    bank_name nvarchar(100) not null,
    created_at datetime not null
);
go

create table Notification (
    notification_id bigint identity(1 , 1) primary key,
    account_id bigint not null,
    title nvarchar(100),
    message nvarchar(255) not null,
    is_read bit,
    created_at datetime not null
);
go

create table OTP (
    otp_id bigint identity(1 , 1) primary key,
    account_id bigint not null,

    otp_code nchar(6) not null,
    purpose nvarchar(50) not null,
    expired_at datetime not null,
    verified bit not null,
    created_at datetime not null
);
go

create table LoginHistory (
    login_id bigint identity(1 , 1) primary key,
    account_id bigint not null,
    login_time datetime not null,
    ip_address varchar(50) not null,
    device nvarchar(100) not null,
    login_status nvarchar(20) not null
);
go