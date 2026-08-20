# Banking System

Ứng dụng quản lý hệ thống ngân hàng: quản lý khách hàng, nhân viên, tài khoản ngân hàng, thẻ, giao dịch, khoản vay, tiết kiệm và các nghiệp vụ liên quan.

## 1. Mục tiêu dự án

Xây dựng một hệ thống backend (và có thể mở rộng frontend) cho phép:

- **Khách hàng (Customer)**: đăng ký/đăng nhập, quản lý tài khoản ngân hàng, mở thẻ, chuyển khoản, gửi tiết kiệm, vay vốn, xem lịch sử giao dịch, nhận thông báo.
- **Nhân viên (Employee)**: xử lý hồ sơ khách hàng, duyệt khoản vay, quản lý chi nhánh, hỗ trợ nghiệp vụ tại quầy.
- **Quản trị viên (Admin)**: quản lý tài khoản hệ thống, phân quyền, giám sát bảo mật (đăng nhập, OTP).

## 2. Kiến trúc & Công nghệ đề xuất

| Thành phần       | Gợi ý công nghệ                                  |
|-------------------|--------------------------------------------------|
| Backend           | Java Spring Boot / .NET Core / Node.js (Express) |
| Database          | SQL Server (theo schema hiện tại)                |
| Authentication    | JWT + OTP (2FA) qua bảng `OTP`                   |
| Frontend (web)    | React / Angular / Vue                            |
| Mobile (tuỳ chọn) | Flutter / React Native                           |
| ORM               | Entity Framework / Hibernate / Sequelize          |
| Cache/Queue       | Redis (session, OTP cache), RabbitMQ (thông báo) |

## 3. Cấu trúc Database (dựa trên schema.sql)

### 3.1. Nhóm Tài khoản & Định danh
- **Account**: tài khoản đăng nhập hệ thống (dùng chung cho Customer & Employee). Có `role`, `status`, `password_hash`.
- **Customer**: hồ sơ khách hàng, liên kết `account_id` và `branch_id`.
- **Employee**: hồ sơ nhân viên, có `position`, `hired_at`, liên kết `account_id` và `branch_id`.
- **Branch**: chi nhánh ngân hàng.

### 3.2. Nhóm Nghiệp vụ tài chính
- **BankingAccount**: tài khoản ngân hàng của khách hàng (số dư, loại tài khoản, tiền tệ).
- **Card**: thẻ ngân hàng gắn với `BankingAccount`.
- **BankTransaction**: giao dịch chuyển/nhận tiền giữa các `BankingAccount`.
- **Loan**: khoản vay của khách hàng, được nhân viên (`approved_by`) duyệt.
- **SavingAccount**: sổ tiết kiệm liên kết với `BankingAccount` nguồn.
- **Beneficiary**: danh sách người thụ hưởng đã lưu để chuyển khoản nhanh.

### 3.3. Nhóm Hệ thống & Bảo mật
- **Notification**: thông báo gửi tới `Account`.
- **OTP**: mã xác thực OTP cho các thao tác nhạy cảm.
- **LoginHistory**: lịch sử đăng nhập (IP, thiết bị, trạng thái).

### 3.4. Sơ đồ quan hệ (rút gọn)

```
Account 1---1 Customer
Account 1---1 Employee
Branch  1---N Customer
Branch  1---N Employee
Customer 1---N BankingAccount
BankingAccount 1---N Card
BankingAccount 1---N BankTransaction (from/to)
Customer 1---N Loan
BankingAccount 1---N SavingAccount
Customer 1---N Beneficiary
Account 1---N Notification
Account 1---N OTP
Account 1---N LoginHistory
```

> ⚠️ **Lưu ý**: File `schema.sql` hiện tại chưa khai báo `FOREIGN KEY` tường minh. Khuyến nghị bổ sung constraint để đảm bảo toàn vẹn tham chiếu (ví dụ `Customer.account_id` → `Account.account_id`, `BankTransaction.from_bank_account_id` → `BankingAccount.bank_account_id`, v.v.)

## 4. Các module chức năng chính

### 4.1. Module Xác thực (Auth)
- Đăng ký / đăng nhập / đăng xuất
- Xác thực 2 lớp bằng OTP (SMS/Email)
- Quản lý phiên đăng nhập, lịch sử đăng nhập (`LoginHistory`)
- Phân quyền theo `role` (Customer / Employee / Admin)

### 4.2. Module Quản lý khách hàng (Customer Management)
- CRUD hồ sơ khách hàng
- Gán khách hàng vào chi nhánh
- Tra cứu theo `citizen_id`, `full_name`

### 4.3. Module Quản lý nhân viên (Employee Management)
- CRUD hồ sơ nhân viên
- Quản lý chức vụ (`position`), trạng thái làm việc
- Phân công theo chi nhánh

### 4.4. Module Tài khoản ngân hàng (Banking Account)
- Mở/đóng tài khoản
- Xem số dư khả dụng (`available_balance`) vs số dư thực (`balance`)
- Hỗ trợ đa loại tài khoản, đa tiền tệ

### 4.5. Module Thẻ (Card)
- Phát hành thẻ mới
- Khoá/mở thẻ, gia hạn
- Quản lý trạng thái thẻ

### 4.6. Module Giao dịch (Transaction)
- Chuyển khoản nội bộ / liên ngân hàng
- Tính phí giao dịch (`fee`)
- Lịch sử giao dịch theo tài khoản

### 4.7. Module Vay vốn (Loan)
- Tạo hồ sơ vay
- Nhân viên duyệt/từ chối khoản vay
- Theo dõi dư nợ, lịch trả góp hàng tháng

### 4.8. Module Tiết kiệm (Saving)
- Mở sổ tiết kiệm theo kỳ hạn
- Tính lãi đáo hạn
- Tất toán sổ tiết kiệm

### 4.9. Module Người thụ hưởng (Beneficiary)
- Lưu danh sách người nhận thường xuyên
- Chuyển khoản nhanh tới beneficiary đã lưu

### 4.10. Module Thông báo (Notification)
- Gửi thông báo giao dịch, khuyến mãi, cảnh báo bảo mật
- Đánh dấu đã đọc/chưa đọc

## 5. Vấn đề cần xử lý trước khi triển khai

1. **Thêm Foreign Key constraints** cho toàn bộ các bảng liên quan.
2. **Sửa tên cột** `INTerest_rate` → `interest_rate` (ở cả `Loan` và `SavingAccount`) cho nhất quán.
3. **Thêm Index** cho các cột tra cứu thường xuyên: `Account.email`, `BankingAccount.bank_account_number`, `Customer.citizen_id`.
4. **Ràng buộc CHECK** cho các cột `status`, `role`, `account_type`... để giới hạn giá trị hợp lệ (enum-like).
5. **Bổ sung bảng liên kết** nếu cần: ví dụ `Card` nên có FK rõ ràng tới `BankingAccount`.
6. **Mã hoá dữ liệu nhạy cảm**: `citizen_id`, `card_number` nên được mã hoá hoặc mask khi hiển thị.
7. **Xử lý transaction đồng thời (concurrency)**: dùng transaction/lock khi cập nhật số dư để tránh race condition.

## 6. Cài đặt (placeholder – cập nhật theo stack thực tế)

```bash
# Clone project
git clone <repo-url>
cd banking-system

# Cấu hình database
# Cập nhật connection string trong file config (appsettings.json / application.properties / .env)

# Chạy migration / khởi tạo schema
sqlcmd -S <server> -i schema.sql

# Cài dependencies
npm install   # hoặc mvn install / dotnet restore

# Chạy ứng dụng
npm run dev   # hoặc tương ứng với stack đã chọn
```

## 7. Roadmap đề xuất

- [ ] Giai đoạn 1: Thiết kế lại schema hoàn chỉnh (thêm FK, index, constraint)
- [ ] Giai đoạn 2: Xây dựng Auth module (đăng ký/đăng nhập/OTP)
- [ ] Giai đoạn 3: CRUD Customer/Employee/Branch
- [ ] Giai đoạn 4: Module BankingAccount + Card
- [ ] Giai đoạn 5: Module Transaction (chuyển khoản)
- [ ] Giai đoạn 6: Module Loan + SavingAccount
- [ ] Giai đoạn 7: Notification + Dashboard thống kê
- [ ] Giai đoạn 8: Kiểm thử bảo mật, tối ưu hiệu năng, triển khai

## 8. Tác giả

- **Huynh Bao Khang**
