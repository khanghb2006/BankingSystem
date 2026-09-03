USE BankingSystem;
GO

IF OBJECT_ID('dbo.sp_notification_create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_notification_create;
GO