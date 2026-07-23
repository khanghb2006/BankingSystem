/*
======================================================
    Banking System Database Sequences
    Author      : Huynh Bao Khang
    Description : Generate unique IDs for all entities.
======================================================
*/

use BankingSystem;
go

/* 
------------------------------------------------------
    CustomerID Sequences
    Format : 
        CIF000001
        CIF000002
------------------------------------------------------
*/
create sequence seq_CustomerID
    as int
    start with 1
    increment by 1
go

/*
------------------------------------------------------
    Employee Sequences
    Format : 
        EMP000001
        EMP000002
------------------------------------------------------
*/
create sequence seq_EmployeeID
    as int
    start with 1
    increment by 1
go

/* 
------------------------------------------------------
    BranchID Sequences
    Format : 
        BR000001
        BR000002
------------------------------------------------------
*/
create sequence seq_BranchID
    as int
    start with 1
    increment by 1
go

/* 
------------------------------------------------
    CardID Sequences
    Format : 
        CD000001
        CD000002
------------------------------------------------
*/

create sequence seq_CardID
    as int
    start with 1
    increment by 1
go

/* 
------------------------------------------------
    TransactionID Sequences
    Format : 
        TR000001
        TR000002
------------------------------------------------
*/
create sequence seq_TransactionID
    as int
    start with 1
    increment by 1
go

/* 
------------------------------------------------
    LoanID Sequences
    Format : 
        LN000001
        LN000002
------------------------------------------------
*/
create sequence seq_LoanID
    as int
    start with 1
    increment by 1
go

/* 
------------------------------------------------
    SavingAccountID Sequences
    Format : 
        SA000001
        SA000002
------------------------------------------------
*/
create sequence seq_SavingAccountID
    as int
    start with 1
    increment by 1
go

/*
------------------------------------------------
    Beneficiary Sequences
    Format : 
        BF000001
        BF000002
------------------------------------------------
*/
create sequence seq_BeneficiaryID
    as int
    start with 1
    increment by 1
go

/* 
------------------------------------------------
    Notification Sequences
    Format : 
        NT000001
        NT000002
------------------------------------------------
*/
create sequence seq_NotificationID
    as int
    start with 1
    increment by 1
go 

/* 
------------------------------------------------
    OTP Sequences
    Format : 
        OTP000001
        OTP000002
------------------------------------------------
*/
create sequence seq_OTPID
    as int
    start with 1
    increment by 1

/* 
------------------------------------------------
    Login History Sequences
    Format : 
        LG000001
        LG000002
------------------------------------------------
*/
create sequence seq_LoginHistoryID
    as int
    start with 1
    increment by 1
go

/*
------------------------------------------------
    AccountID Sequences
    Format : 
        AC000001
        AC000002
------------------------------------------------
*/
create sequence seq_AccountID
    as int
    start with 1
    increment by 1

/* 
------------------------------------------------
    AccountNumber Sequences
    Format :
        100000000001
        100000000002 
------------------------------------------------
*/

create sequence seq_AccountNumber
    as bigint
    start with 100000000001
    increment by 1
go