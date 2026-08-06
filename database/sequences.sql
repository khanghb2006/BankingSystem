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

