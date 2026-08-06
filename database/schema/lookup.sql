/* 
========================================
    Banking System Lookup Tables
    Author : Huynh Bao Khang
    Description : Lookup Tables for Banking System
========================================
*/

USE BankingSystem
GO

-- Account Role
CREATE TABLE AccountRole (
    role_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Account Status
CREATE TABLE AccountStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Customer Status
CREATE TABLE CustomerStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);

-- Employee Position
CREATE TABLE EmployeePosition (
    position_name VARCHAR(50) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Employee Status
CREATE TABLE EmployeeStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Branch Status
CREATE TABLE BranchStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Banking Account Type
CREATE TABLE BankingAccountType (
    type_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

--Banking Account Status
CREATE TABLE BankingAccountStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Currency 
CREATE TABLE Currency (
    currency_code VARCHAR(10) PRIMARY KEY,
    currency_name NVARCHAR(50),
    symbol NVARCHAR(10),
    is_active BIT NOT NULL DEFAULT 1
);
GO 

-- Card Type
CREATE TABLE CardType (
    type_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Card Status
CREATE TABLE CardStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Transaction Type
CREATE TABLE TransactionType (
    type_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Transaction Status
CREATE TABLE TransactionStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Loan Type 
CREATE TABLE LoanType (
    type_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Loan Status
CREATE TABLE LoanStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Saving Account Status
CREATE TABLE SavingAccountStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Notification Type
CREATE TABLE NotificationType (
    type_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- OTP Purpose
CREATE TABLE OTPPurpose (
    purpose_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Login History Status
CREATE TABLE LoginHistoryStatus (
    status_name VARCHAR(20) PRIMARY KEY,
    description NVARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
);