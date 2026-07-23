USE master;
GO

-- Chuyển sang Single User và ngắt ngay các session khác
ALTER DATABASE BankingSystem 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO

-- Xóa Database
DROP DATABASE BankingSystem;
GO