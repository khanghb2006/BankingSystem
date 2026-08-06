/*
======================================================
    Banking System Database Indexes
    Author : Huynh Bao Khang
    Description : Performance indexes
======================================================
*/

use BankingSystem;
go

-- Account
create index IX_Account_Username on Account(username);
create index IX_Account_Email on Account(email);
create index IX_Account_PhoneNumber on Account(phone_number);
create index IX_Account_Role on Account(role);
create index IX_Account_Status on Account(status);
create index IX_Account_AccountId on Account(account_id);
go

-- Customer
create index IX_Customer_CustomerId on Customer(customer_id);
create index IX_Customer_FullName on Customer(full_name);
create index IX_Customer_CitizenId on Customer(citizen_id);
create index IX_Customer_Address on Customer(address);
create index IX_Customer_DOB on Customer(dob);
go

-- Employee
create index IX_Employee_EmployeeId on Employee(employee_id);
create index IX_Employee_FullName on Employee(full_name);
create index IX_Employee_CitizenId on Employee(citizen_id);
create index IX_Employee_Address on Employee(address);
create index IX_Employee_Position on Employee(position);
create index IX_Employee_Status on Employee(status);
create index IX_Employee_DOB on Employee(dob);
create index IX_Employee_HiredAt on Employee(hired_at);
go

-- Branch
create index IX_Branch_BranchId on Branch(branch_id);
create index IX_Branch_BranchName on Branch(branch_name);
create index IX_Branch_Address on Branch(address);
create index IX_Branch_Status on Branch(status);
go

-- Banking Account
create index IX_BankingAccount_AccountId on BankingAccount(bank_account_id);
create index IX_BankingAccount_AccountNumber on BankingAccount(bank_account_number);
create index IX_BankingAccount_Currency on BankingAccount(currency);
create index IX_BankingAccount_Type on BankingAccount(account_type);
create index IX_BankingAccount_CloseAt on BankingAccount(closed_at);
create index IX_BankingAccount_Status on BankingAccount(status);
go

-- Card 
create index IX_Card_CardId on Card(card_id);
create index IX_Card_CardNumber on Card(card_number);
create index IX_Card_Type on Card(card_type);
create index IX_Card_ExpiredAt on Card(expired_at);
create index IX_Card_Status on Card(status);
go

-- Loan
create index IX_Loan_LoanId on Loan(loan_id);
create index IX_Loan_LoanType on Loan(loan_type);
create index IX_Loan_Status on Loan(status);
create index IX_Loan_ApprovedBy on Loan(approved_by);
create index IX_Loan_Duration on Loan(duration_months);
create index IX_Loan_Amount on Loan(amount);
go

-- Saving Account
create index IX_SavingAccount_SavingId on SavingAccount(saving_id);
create index IX_SavingAccount_SourceBankAccountId on SavingAccount(source_bank_account_id);
create index IX_SavingAccount_DepositAmount on SavingAccount(deposit_amount);
create index IX_SavingAccount_InterestRate on SavingAccount(interest_rate);
create index IX_SavingAccount_TermMonths on SavingAccount(term_months);
create index IX_SavingAccount_Status on SavingAccount(status);
go

-- Beneficiary
create index IX_Beneficiary_BeneficiaryId on Beneficiary(beneficiary_id);
create index IX_Beneficiary_Name on Beneficiary(beneficiary_name);
create index IX_Beneficiary_BankName on Beneficiary(bank_name);
go 

-- Notification
create index IX_Notification_NotificationId on Notification(notification_id);
create index IX_Notification_Title on Notification(title);
create index IX_Notification_IsRead on Notification(is_read);
go

-- OTP
create index IX_OTP_OTPId on OTP(otp_id);
create index IX_OTP_Code on OTP(otp_code);
create index IX_OTP_Purpose on OTP(purpose);
create index IX_OTP_Verified on OTP(verified);
go

-- Login History
create index IX_LoginHistory_LoginHistoryId on LoginHistory(login_id);
create index IX_LoginHistory_LoginAt on LoginHistory(login_time);
create index IX_LoginHistory_IPAddress on LoginHistory(ip_address);
create index IX_LoginHistory_Device on LoginHistory(device);
create index IX_LoginHistory_Status on LoginHistory(login_status);
go
