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
        CIF000001
        CIF000002
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
        EMP000001
        EMP000002
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

