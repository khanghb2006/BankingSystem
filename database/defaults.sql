/*
====================================================
    Banking System Default Values
    Author : Khang Huynh Bao
    Description : Default Constraints
====================================================
*/

use BankingSystem;
go

/* Customer */
alter table Customer
    add constraint DF_Customer_CreatedAt
            default getdate() for created_at,
        constraint DF_Customer_Status
            default 'Active' for status;
go

/* Employee */
alter table Employee 
    add constraint DF_Employee_Status
        default 'Active' for status;
go

/* Branch */
alter table Branch
    add constraint DF_Branch_CreatedAt
        default getdate() for created_at;
go

/* Account */
alter table Account
    add constraint DF_Account_Balance
            default 0 for balance,
        constraint DF_Account_AvailableBalance
            default 0 for available_balance,
        constraint DF_Account_OpenedAt
            default getdate() for opened_at,
        constraint DF_Account_Status
            default 'Active' for status;
go

/* Card */
alter table Card
    add constraint DF_Card_IssuedAt
            default getdate() for issued_at,
        constraint DF_Card_Status
            default 'Active' for status;
go

/* Bank Transaction */
alter table BankTransaction
    add constraint DF_BankTransaction_CreatedAt
            default getdate() for created_at,
        constraint DF_BankTransaction_Status
            default 'Pending' for status,
        constraint DF_BankTransaction_Fee
            default 0 for fee;
go

/* Loan */
alter table Loan
    add constraint DF_Loan_Status
        default 'Active' for status;
go

/* Savings Account */
alter table SavingAccount
    add constraint DF_SavingAccount_Status
        default 'Active' for status;
go

/* Beneficiary */
alter table Beneficiary
    add constraint DF_Beneficiary_CreatedAt
        default getdate() for created_at;
go

/* Notification */
alter table Notification
    add constraint DF_Notification_Isread
            default 0 for is_read,
        constraint DF_Notification_CreatedAt
            default getdate() for created_at;
go

/* OTP */
alter table OTP
    add constraint DF_OTP_CreatedAt
            default getdate() for created_at,
        constraint DF_OTP_Verified
            default 0 for verified;
go

/* Login History */
alter table LoginHistory
    add constraint DF_LoginHistory_Time
        default getdate() for login_time;