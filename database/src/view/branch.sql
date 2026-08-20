/**
    View - Branch
    Description: This view provides information about bank branches details.
*/

USE BankingSystem;
GO

CREATE OR ALTER VIEW vw_Branch AS
SELECT
    branch_id,
    branch_name,
    address,
    phone_number,
    created_at,
    updated_at,
    status
FROM Branch;