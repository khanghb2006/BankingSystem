/*
======================================================
    Banking System Database Indexes
    Author : Huynh Bao Khang
    DescriptiON : Performance indexes
======================================================
*/

USE BankingSystem;
GO

-- Account
CREATE INDEX IX_Account_USERNAME ON Account(username);
CREATE INDEX IX_Account_Email ON Account(email);
CREATE INDEX IX_Account_PhoneNumber ON Account(phone_number);
CREATE INDEX IX_Account_Role ON Account(role);
CREATE INDEX IX_Account_Status ON Account(status);
CREATE INDEX IX_Account_AccountId ON Account(account_id);
GO

-- Customer
CREATE INDEX IX_Customer_CustomerId ON Customer(customer_id);
CREATE INDEX IX_Customer_FullName ON Customer(full_name);
CREATE INDEX IX_Customer_CitizenId ON Customer(citizen_id);
CREATE INDEX IX_Customer_Address ON Customer(address);
CREATE INDEX IX_Customer_DOB ON Customer(dob);
GO

-- Employee
CREATE INDEX IX_Employee_EmployeeId ON Employee(employee_id);
CREATE INDEX IX_Employee_FullName ON Employee(full_name);
CREATE INDEX IX_Employee_CitizenId ON Employee(citizen_id);
CREATE INDEX IX_Employee_Address ON Employee(address);
CREATE INDEX IX_Employee_PositiON ON Employee(positiON);
CREATE INDEX IX_Employee_Status ON Employee(status);
CREATE INDEX IX_Employee_DOB ON Employee(dob);
CREATE INDEX IX_Employee_HiredAt ON Employee(hired_at);
GO

-- Branch
CREATE INDEX IX_Branch_BranchId ON Branch(branch_id);
CREATE INDEX IX_Branch_BranchName ON Branch(branch_name);
CREATE INDEX IX_Branch_Address ON Branch(address);
CREATE INDEX IX_Branch_Status ON Branch(status);
GO

-- Banking Account
CREATE INDEX IX_BankingAccount_AccountId ON BankingAccount(bank_account_id);
CREATE INDEX IX_BankingAccount_AccountNumber ON BankingAccount(bank_account_number);
CREATE INDEX IX_BankingAccount_Currency ON BankingAccount(currency);
CREATE INDEX IX_BankingAccount_Type ON BankingAccount(account_type);
CREATE INDEX IX_BankingAccount_CloseAt ON BankingAccount(closed_at);
CREATE INDEX IX_BankingAccount_Status ON BankingAccount(status);
GO

-- Card 
CREATE INDEX IX_Card_CardId ON Card(card_id);
CREATE INDEX IX_Card_CardNumber ON Card(card_number);
CREATE INDEX IX_Card_Type ON Card(card_type);
CREATE INDEX IX_Card_ExpiredAt ON Card(expired_at);
CREATE INDEX IX_Card_Status ON Card(status);
GO

-- Loan
CREATE INDEX IX_Loan_LoanId ON Loan(loan_id);
CREATE INDEX IX_Loan_LoanType ON Loan(loan_type);
CREATE INDEX IX_Loan_Status ON Loan(status);
CREATE INDEX IX_Loan_ApprovedBy ON Loan(approved_by);
CREATE INDEX IX_Loan_Duration ON Loan(duration_months);
CREATE INDEX IX_Loan_Amount ON Loan(amount);
GO

-- Saving Account
CREATE INDEX IX_SavingAccount_SavingId ON SavingAccount(saving_id);
CREATE INDEX IX_SavingAccount_SourceBankAccountId ON SavingAccount(source_bank_account_id);
CREATE INDEX IX_SavingAccount_DepositAmount ON SavingAccount(deposit_amount);
CREATE INDEX IX_SavingAccount_InterestRate ON SavingAccount(interest_rate);
CREATE INDEX IX_SavingAccount_TermMMonths ON SavingAccount(term_months);
CREATE INDEX IX_SavingAccount_Status ON SavingAccount(status);
GO

-- Beneficiary
CREATE INDEX IX_Beneficiary_BeneficiaryId ON Beneficiary(beneficiary_id);
CREATE INDEX IX_Beneficiary_Name ON Beneficiary(beneficiary_name);
CREATE INDEX IX_Beneficiary_BankName ON Beneficiary(bank_name);
GO 

-- NotificatiON
CREATE INDEX IX_NotificatiON_NotificatiONId ON NotificatiON(notification_id);
CREATE INDEX IX_NotificatiON_Title ON NotificatiON(title);
CREATE INDEX IX_NotificatiON_IsRead ON NotificatiON(is_read);
GO

-- OTP
CREATE INDEX IX_OTP_OTPId ON OTP(otp_id);
CREATE INDEX IX_OTP_Code ON OTP(otp_code);
CREATE INDEX IX_OTP_Purpose ON OTP(purpose);
CREATE INDEX IX_OTP_Verified ON OTP(verified);
GO

-- Login History
CREATE INDEX IX_LoginHistory_LoginHistoryId ON LoginHistory(login_id);
CREATE INDEX IX_LoginHistory_LoginAt ON LoginHistory(login_time);
CREATE INDEX IX_LoginHistory_IPAddress ON LoginHistory(ip_address);
CREATE INDEX IX_LoginHistory_Device ON LoginHistory(device);
CREATE INDEX IX_LoginHistory_Status ON LoginHistory(login_status);
GO
