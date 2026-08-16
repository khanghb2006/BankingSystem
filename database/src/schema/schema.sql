/*
=============================================
    Banking System Database Schema
    Author : Huynh Bao Khang
    Description : Create all database tables
=============================================
*/

CREATE DATABASE BankingSystem;
GO

use BankingSystem;
GO

CREATE TABLE Account (
    account_id BIGINT IDENTITY(1,1) PRIMARY KEY,

    username VARCHAR(50) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    image_url VARCHAR(2048),
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    status VARCHAR(20) NOT NULL
);
GO

CREATE TABLE Customer (
    customer_id NCHAR(10) PRIMARY KEY,
    account_id BIGINT NOT NULL,
    branch_id NCHAR(10) NOT NULL,

    full_name NVARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    citizen_id VARCHAR(20) NOT NULL,
    address NVARCHAR(255) NOT NULL,
    
    created_at DATETIME NOT NULL,
    updated_at DATETIME
);
GO

CREATE TABLE Employee (
    employee_id NCHAR(10) PRIMARY KEY,
    account_id BIGINT NOT NULL,
    branch_id NCHAR(10) NOT NULL,

    position VARCHAR(50) NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    citizen_id VARCHAR(20) NOT NULL,
    address NVARCHAR(255) NOT NULL,

    status NVARCHAR(20) NOT NULL,
    hired_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME
);
GO

CREATE TABLE Branch (
    branch_id NCHAR(10) PRIMARY KEY,
    branch_name NVARCHAR(100) NOT NULL,
    address NVARCHAR(100),
    phone_number VARCHAR(20) NOT NULL,

    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    status NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE BankingAccount (
    bank_account_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_id NCHAR(10) NOT NULL,

    bank_account_number NCHAR(20) NOT NULL,
    balance DECIMAL(18, 2) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    currency NVARCHAR(10) NOT NULL,
    available_balance DECIMAL(18, 2) NOT NULL,

    opened_at DATETIME NOT NULL,
    closed_at DATETIME,
    status NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE Card (
    card_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    bank_account_id BIGINT NOT NULL,

    card_number VARCHAR(20) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    expired_at DATE,
    cvv_hash VARCHAR(255) NOT NULL,
    issued_at DATETIME NOT NULL,
    status NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE BankTransaction (
    transaction_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    from_bank_account_id BIGINT NOT NULL,
    to_bank_account_id BIGINT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    fee DECIMAL(18, 2) NOT NULL,
    description NVARCHAR(255),
    created_at DATETIME NOT NULL,
    status NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE Loan (
    loan_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    customer_id NCHAR(10) NOT NULL,

    loan_type VARCHAR(20) NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    INTerest_rate DECIMAL(18, 2) NOT NULL,
    remaining_balance DECIMAL(18, 2) NOT NULL,
    duration_months INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_payment DECIMAL(18, 2) NOT NULL,

    approved_by NCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL
);
GO

CREATE TABLE SavingAccount (
    saving_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    source_bank_account_id BIGINT NOT NULL,
    deposit_amount DECIMAL(18, 2) NOT NULL,
    INTerest_rate DECIMAL(18, 2) NOT NULL,
    term_months INT NOT NULL,
    start_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    status NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE Beneficiary (
    beneficiary_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    customer_id NCHAR(10) NOT NULL,
    beneficiary_name NVARCHAR(50) NOT NULL,
    bank_account_id BIGINT NOT NULL,
    bank_name NVARCHAR(100) NOT NULL,
    created_at DATETIME NOT NULL
);
GO

CREATE TABLE Notification (
    notification_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    account_id BIGINT NOT NULL,
    title NVARCHAR(100),
    message NVARCHAR(255) NOT NULL,
    is_read bit,
    created_at DATETIME NOT NULL
);
GO

CREATE TABLE OTP (
    otp_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    account_id BIGINT NOT NULL,

    otp_code NCHAR(6) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    expired_at DATETIME NOT NULL,
    verified bit NOT NULL,
    created_at DATETIME NOT NULL
);
GO

CREATE TABLE LoginHistory (
    login_id BIGINT IDENTITY(1 , 1) PRIMARY KEY,
    account_id BIGINT NOT NULL,
    login_time DATETIME NOT NULL,
    ip_address VARCHAR(50) NOT NULL,
    device NVARCHAR(100) NOT NULL,
    login_status VARCHAR(20) NOT NULL
);
GO