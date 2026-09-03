USE BankingSystem;
GO

-- Dọn 2 cái sai (thường không có sẵn, để cho chắc)
IF OBJECT_ID('FK_Customer_Status', 'F') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT FK_Customer_Status;
IF OBJECT_ID('DF_Customer_Status', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_Status;
GO

-- Thêm lại FOREIGN KEY
IF OBJECT_ID('FK_Customer_Account', 'F') IS NULL
    ALTER TABLE Customer ADD CONSTRAINT FK_Customer_Account
        FOREIGN KEY(account_id) REFERENCES Account(account_id);
GO

IF OBJECT_ID('FK_Customer_Branch', 'F') IS NULL
    ALTER TABLE Customer ADD CONSTRAINT FK_Customer_Branch
        FOREIGN KEY(branch_id) REFERENCES Branch(branch_id);
GO

-- Thêm lại DEFAULT
IF OBJECT_ID('DF_Customer_CreatedAt', 'D') IS NULL
    ALTER TABLE Customer ADD CONSTRAINT DF_Customer_CreatedAt
        DEFAULT GETDATE() FOR created_at;
GO

IF OBJECT_ID('DF_Customer_UpdatedAt', 'D') IS NULL
    ALTER TABLE Customer ADD CONSTRAINT DF_Customer_UpdatedAt
        DEFAULT GETDATE() FOR updated_at;
GO