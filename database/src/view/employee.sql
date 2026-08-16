/*
====================================================
    Employee Views
    Author : Huynh Bao Khang
    Description : Views related to employees
====================================================
*/

USE BankingSystem;
GO

/* 
------------------------------------------------------
    View: vw_EmployeeDetails
    Description : Public employee information (masked sensitive data)
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_EmployeeDetails 
AS
    SELECT 
        E.employee_id,
        E.account_id,

        A.username,
        dbo.fn_mask_email(A.email) AS masked_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_phone,
        dbo.fn_mask_citizen_id(E.citizen_id) AS masked_citizen_id,
        E.full_name,
        E.gender,
        E.dob,

        E.branch_id,
        E.position,
        E.hired_at,
        
        A.status,
        E.created_at,
        E.updated_at
    FROM Employee E
    JOIN Account A ON E.account_id = A.account_id;
GO

/* 
------------------------------------------------------
    View: vw_EmployeeSummary
    Description : Lightweight employee information for employee listing and searching
------------------------------------------------------
*/
CREATE OR ALTER VIEW vw_EmployeeSummary
AS
    SELECT 
        E.employee_id,
        E.full_name,
        E.position,
        E.branch_id,

        dbo.fn_mask_email(A.email) AS masked_email,
        dbo.fn_mask_phone_number(A.phone_number) AS masked_phone,
        dbo.fn_mask_citizen_id(E.citizen_id) AS masked_citizen_id,
        
        E.hired_at,
        A.status
    FROM Employee E
    JOIN Account A ON E.account_id = A.account_id;
GO