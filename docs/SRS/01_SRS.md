### 1. Introduction
#### 1.1 Purpose
This document describes the software requirements for the Digital Banking System. It serves as a reference for the design , development, testing , and maintaince of the application

#### 1.2 Scope 
The Digital Banking System allows customers to manage their bank accounts online. Users can register, log in, transfer money, check balances, view transaction history, apply for loans, and receive notifications. Aministrator can manage users, monitor transactions, and approve requests.

#### 1.3 Intended Audience
This document is intended for:
* Software Developers
* Testers
* Project Maintainers
* Recruiters (Portfolio Review)

### 2. Overal Description
#### 2.1 Product Perspective
The system is a web-based banking application consisting of
* React Frontend
* FastAPI Backend
* C++ High-performance Services
* PostgreSQL Database

#### 2.2 Product Functions
The system provides the following major features:
* User Authencation
* Account Management
* Money Transfer
* Transaction History
* Loan Management
* Notification System
* Admin Dashboard

#### 2.3 User Classes
##### Customer
Can : 
* Register
* Login
* Manage profie
* Open bank account
* Transfer money
* View transaction
* Apply for loans

##### Administrator
Can :
* Manage users
* Lock/Unlock accounts
* Review loan requests
* View reports
* Monitor system logs

### 3. Funtional Requirements
#### 1. Authentication
* FR-01 : Người dùng có thể đăng ký tài khoản.
* FR-02 : Người dùng đăng nhập bằng email và password.
* FR-03 : Người dùng đăng xuất.
* FR-04 : Người dùng đổi mật khẩu.
* FR-05 : Người dùng quên mật khẩu.

#### 2. User Profile
* FR-06 : Xem thông tin cá nhân.
* FR-07 : Cập nhật thông tin.
* FR-08 : Đổi ảnh đại diện.

#### 3. Bank Account
* FR-09 : Mở tài khoản ngân hàng.
* FR-10 : Đóng tài khoản.
* FR-11 : Xem số dư.
* FR-12 : Xem thông tin tài khoản.

#### 4. Transaction
* FR-13 : Chuyển tiền.
* FR-14 : Nạp tiền.
* FR-15 : Rút tiền.
* FR-16 : Chuyển tiền nội bộ.
* FR-17 : Chuyển tiền liên ngân hàng.
* FR-18 : Xem lịch sử giao dịch.
* FR-19 : Tìm kiếm giao dịch.

#### 5. Notification
* FR-20 : Thông báo khi giao dịch thành công.
* FR-21 : Thông báo khi đăng nhập.

#### 6. Loan
* FR-22 : Đăng ký khoản vay.
* FR-23 : Xem thông tin khoản vay.
* FR-24 : Thanh toán khoản vay.

#### 7. Admin
* FR-25 : Quản lý người dùng.
* FR-26 : Khóa tài khoản.
* FR-27 : Mở khóa tài khoản.
* FR-28 : Quản lý khoản vay.
* FR-29 : Xem thống kê.
* FR-30 : Xem log hệ thống.


### 2. Non-functional Requirements
#### Security
* Password được mã hóa bằng BCrypt.
* JWT Authentication.
* HTTPS khi triển khai.
* Phân quyền Admin và Customer.

#### Performance
* API phản hồi dưới 2 giây.
* Hỗ trợ khoảng 100 người dùng đồng thời.

#### Reliability
* Mỗi giao dịch được lưu vào database.
* Có logging để kiểm tra lỗi.

#### Maintainability
* Áp dụng Clean Architecture.
* SOLID.
* Repository Pattern.
* Dependency Injection.

#### Scalability
##### Backend chia thành:
* Python API
* C++ Service
* Database
để dễ mở rộng.

#### Database
* Sử dụng PostgreSQL.
* Chuẩn hóa dữ liệu đến 3NF.

### 4. Non-functional Requirements
|**Category**   | **Requirement**                         |
|---------------|-----------------------------------------|
| Security      | Passwords must be encrypted using BCrypt|
| Security| JWT Autthencation is required | 
| Security | HTTPS must be used in production|
| Performance | API response time should be under 2 seconds|
| Performance | Support at least 100 current users | 
| Reliability | Every transaction must be recorded in the database |
| Reliability | Logging must be enabled for important operations|
|Maintainability | Follow Clean Architecture|
|Maintainability | Follow SOLID principles |
|Maintainbility | Use repository Pattern and Dependency Injection |
|Scalability | Backend services should be independently deployable|
|Database | PostgreSQL is used with normalization up to 3NF|

### 5. Use Cases
#### UC-01 Register Account
**Use case Id** : UC-01

**Use case name** : Register Account

**Primary Actor** : Customer

**Description** : Allows a new customer to create an account in the banking system

**Preconditions**:
* The customer does not have an existing account
* The registration page is available

**Postconditions** : 
* A new user account is successfully created
* The customer can log in using the registered credentials

**Main Flow** 
1. The customer opens the registration page
2. The customer enters personal information
3. The customer enters an email address and password
4. The customer clicks the Register button
5. The system validates the input
6. The system creates a new account
7. The system displays a successfully registration message

**Alternative Flow**
The email address already exists
* The system displays an error message
* The customer enters another email address

**Exception Flow**
* Database connection fails
* The system displays an unexpected error message

#### UC-02 : Login

#### UC-03 : Transfer Money

#### UC-04 : Deposit Money

#### UC-05 : Withdraw Money

#### UC-06 : View Transaction History

#### UC-07 : Apply for a Loan

#### UC-08 : Manage Users

### 6. Future Scope
Future improvements include : 
* QR Payment
* Credit Card Management
* Multi-factor Authencation(MFA)
* Investment and Savingss Accounts
* Mobile Application
* AI-based Fraund Detection
* Real-time Notification via WebSocket




