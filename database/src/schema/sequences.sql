/*
======================================================
    Banking System Database Sequences
    Author      : Huynh Bao Khang
    Description : Generate unique IDs for all entities.
======================================================
*/

USE BankingSystem;
GO

/* 
------------------------------------------------------
    CustomerID Sequences
    Format : 
        CIF0000001
        CIF0000002
------------------------------------------------------
*/
CREATE SEQUENCE seq_CustomerID
    as int
    start with 1
    increment by 1
GO

/*
------------------------------------------------------
    Employee Sequences
    Format : 
        EMP0000001
        EMP0000002
------------------------------------------------------
*/
CREATE SEQUENCE seq_EmployeeID
    as int
    start with 1
    increment by 1
GO

/* 
------------------------------------------------------
    BranchID Sequences
    Format : 
        BR000001
        BR000002
------------------------------------------------------
*/
CREATE SEQUENCE seq_BranchID
    as int
    start with 1
    increment by 1
GO

