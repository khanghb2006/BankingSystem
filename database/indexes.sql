/*
======================================================
    Banking System Database Indexes
    Author : Huynh Bao Khang
    Description : Performance indexes
======================================================
*/

use BankingSystem;
go

/* Customer */
create index IX_Customer_Email on Customer(email);
create index IX_Customer_PhoneNumber on Customer(phone_number);
create index IX_Customer_CitizenID on Customer(citizen_id);
go

/* Employee */
create index IX_Employee_Email on Employee(email);
create index IX_Employee_PhoneNumber on Employee(phone_number);
create index IX_Employee_BranchID on Employee(branch_id);
go

/* Branch */
create index IX_Branch_BranchCode on Branch(branch_code);
create index IX_Branch_City on Branch(city);
go

/* Account */
create index IX_Account_AccountNumber on Account(account_number);
create index IX_Account_CustomerID on Account(customer_id);
create index IX_Account_BranchID on Account(branch_id);
create index IX_Account_Status on Account(status);
go

/* Card */
create index IX_Card_Number on Card(card_number);
create index IX_Card_AccountID on Card(account_id);
go

/* Bank Transaction */
create index IX_BankTransaction_Sender on BankTransaction(sender_account_id);
create index IX_BankTransaction_Receiver on BankTransaction(receiver_account_id);
create index IX_BankTransaction_Date on BankTransaction(created_at);
create index IX_BankTransaction_Status on BankTransaction(status);
go

/* Composite Indexes */
create index IX_Transaction_Sender_Date on BankTransaction(sender_account_id , created_at);
go

/* Loan */
create index IX_Loan_CustomerID on Loan(customer_id);
create index IX_Loan_Status on Loan(status);
go

/* Savings Account */
create index IX_SavingAccount_CustomerID on SavingAccount(deposit_account_id);
create index IX_SavingAccount_Status on SavingAccount(status);
go

/* Beneficiary */
create index IX_Beneficiary_CustomerID on Beneficiary(customer_id);
create index IX_Beneficiary_AccountNumber on Beneficiary(beneficiary_account_number);
go

/* Notification */
create index IX_Notification_CustomerID on Notification(customer_id);
create index IX_Notification_IsRead on Notification(is_read);
go

/* OTP */
create index IX_OTP_CustomerID on OTP(customer_id);
create index IX_OTP_ExpiredAt on OTP(expired_at);
go

/* Login History */
create index IX_LoginHistory_CustomerID on LoginHistory(customer_id);
create index IX_LoginHistory_LoginTime on LoginHistory(login_time);
go