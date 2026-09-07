# PLAN.md — Kế hoạch triển khai Banking System

> Tài liệu này là hợp đồng làm việc chung cho 3 tầng: **SQL Server (đã có)** → **Spring Boot API** → **React + TypeScript**, cộng thêm **C++ core** (mô hình nghiệp vụ OOP + đồng bộ DB).
> Mọi con số / định dạng / tên gọi phải theo đúng **§1 Hợp đồng chuẩn dùng chung** để frontend và backend không xung đột.

---

## Mục lục

- [0. Tổng quan & kiến trúc](#0-tổng-quan--kiến-trúc)
- [1. Hợp đồng chuẩn dùng chung (Shared Contract)](#1-hợp-đồng-chuẩn-dùng-chung-shared-contract)
- [2. Tầng Database — sửa lỗi & bổ sung](#2-tầng-database--sửa-lỗi--bổ-sung)
- [3. Backend — Spring Boot](#3-backend--spring-boot)
- [4. Frontend — React + TypeScript](#4-frontend--react--typescript)
- [5. C++ Core — code OOP nghiệp vụ ngân hàng](#5-c-core--code-oop-nghiệp-vụ-ngân-hàng)
- [6. Thứ tự thực hiện (Roadmap)](#6-thứ-tự-thực-hiện-roadmap)
- [7. Kiểm thử (Verification)](#7-kiểm-thử-verification)
- [Phụ lục A — Bảng endpoint đầy đủ](#phụ-lục-a--bảng-endpoint-đầy-đủ)
- [Phụ lục B — Bảng mã lỗi theo procedure](#phụ-lục-b--bảng-mã-lỗi-theo-procedure)
- [Phụ lục C — Màn hình frontend → API](#phụ-lục-c--màn-hình-frontend--api)

---

## 0. Tổng quan & kiến trúc

### 0.1 Hiện trạng

| Thành phần | Trạng thái |
|---|---|
| Database (SQL Server, `BankingSystem`) | **Đã có**: 14 bảng + 18 lookup + 14 view + 63 `dbo.sp_*` + 54 `dbo.fn_*`, deploy bằng `database/deploy.ps1` lên `localhost\SQLEXPRESS01` |
| Backend API | **Chưa có** — sẽ dựng Spring Boot |
| Frontend | **Chưa có** — sẽ dựng React + TypeScript (Vite) |
| C++ core | **Chưa có** — greenfield, CMake + nanodbc |

### 0.2 Quyết định stack (đã chốt)

| Vấn đề | Lựa chọn | Lý do |
|---|---|---|
| Database | **Giữ SQL Server**, không migrate | 63 proc + deploy.ps1 đã chạy được, migrate PostgreSQL là làm lại từ đầu |
| Nơi chứa business logic | **Stored procedures** là nguồn sự thật | Đã cài đặt xong, có chống-đua (guarded UPDATE) |
| API cho React | **Spring Boot (Java 17+)** gọi `sp_*` qua JDBC `CallableStatement` | Không ORM, mapper mỏng, hợp SQL Server |
| C++ | **Core domain OOP + đồng bộ DB** — CLI + unit test + batch job; **ghi qua `sp_*`**; tự chạy SQL cho job chưa có proc | Thoả yêu cầu "C++ cho phần core", giữ 1 bản cài đặt quy tắc |
| Frontend | **React + TypeScript** | Cả 2 tài liệu định hướng đều nhắc React |

### 0.3 Kiến trúc 4 tầng

```
┌────────────────┐   HTTP/JSON    ┌────────────────────┐  JDBC {call dbo.sp_*}  ┌──────────────────────┐
│  React + TS    │ ─────────────▶ │  Spring Boot API   │ ─────────────────────▶ │ SQL Server           │
│  (Vite SPA)    │ ◀───────────── │  (envelope, JWT)   │ ◀───────────────────── │ BankingSystem        │
└────────────────┘  ApiResponse   └────────────────────┘   result set + THROW   │  - 63 sp_*  (ghi)    │
                                                                                │  - 14 vw_*  (đọc)    │
┌────────────────────────────────────────────────┐  ODBC {call dbo.sp_*}         │  - 54 fn_*  (validate)│
│  C++ core                                      │ ────────────────────────────▶ │                      │
│  - domain model OOP (Money, Loan, Saving, ...) │  guarded UPDATE (job mới)     └──────────────────────┘
│  - CLI + batch jobs + unit tests              │
└────────────────────────────────────────────────┘
```

**Vì sao không xung đột:** Spring Boot và C++ đều **đi qua `sp_*`** cho mọi thao tác ghi ⇒ chỉ một bản cài đặt quy tắc nghiệp vụ. Cả hai tuân theo cùng §1 cho định dạng dữ liệu. C++ chỉ viết SQL trực tiếp (theo đúng pattern *guarded UPDATE*) cho batch job chưa có proc (đáo hạn tiết kiệm, đánh dấu vay quá hạn).

### 0.4 Bug DB — ✅ đã sửa hết (17 + 1, verify bằng `deploy.ps1 -Seed` ngày 2026-09-07)

Chi tiết từng mục + SQL ở §2.1 / §2.2. Đáng chú ý nhất:
- **#1** `sp_bank_account_get_details` trỏ view sai tên → EXEC lỗi (nay `vw_BankAccountDetails`).
- **#2** `sp_otp_generate_otpcode` cho bỏ qua nhập OTP (replay) → nguy cơ chiếm tài khoản qua `PasswordReset`. Nay vô hiệu OTP cũ bằng `expired_at` thay vì `verified`.
- **#3** `ABS(CHECKSUM(NEWID()))` tràn số INT.MIN trong 5 chỗ sinh số TK/thẻ/OTP → bọc `CONVERT(BIGINT, …)`.
- **#4** `vw_CardDetails` lộ nguyên PAN → `masked_card_number`; số đầy đủ chỉ trả 1 lần ở `sp_card_create`.
- **#5** `vw_CustomerStatistics` nhân đôi `SUM(balance)` + loại khách → viết lại bằng subquery.
- **#6/#15** thêm `UNIQUE` cho `Customer.account_id`, `Employee.account_id`, `Beneficiary(customer_id, bank_account_id)`.

---

## 1. Hợp đồng chuẩn dùng chung (Shared Contract)

> **Cả FE, BE, C++ phải code theo đúng phần này.** Đây là chống-xung-đột số 1.

### 1.1 Định danh (ID)

| Nhóm | Kiểu DB | Định dạng | JSON | Ghi chú |
|---|---|---|---|---|
| `Customer` / `Employee` / `Branch` | `NCHAR(10)` (pad khoảng trắng) | `CIF` + 7 số / `EMP` + 7 số / `BR` + 8 số | **string đã `.trim()`** | vd `"CIF0000001"`. Mọi tầng phải trim khi đọc, pad-phải-tới-10 khi so sánh/ghi |
| `Account`, `BankingAccount`, `Card`, `BankTransaction`, `Loan`, `SavingAccount`, `Beneficiary`, `Notification`, `OTP`, `LoginHistory` | `BIGINT IDENTITY` | số nguyên | **number** | Quy mô đồ án < 2^53 nên an toàn. Nếu lo xa: serialize string |
| `bank_account_number` | `NCHAR(20)` | 20 chữ số | **string** | Không bao giờ dùng number (leading zero) |
| `card_number` | `VARCHAR(20)` | 16 chữ số + Luhn | **string** | idem |

> ⚠️ **Mâu thuẫn cần biết:** `docs/convention.md` nói *mọi* ID là `NCHAR(10)` có prefix (`AC########`, `CA########`, `TR########`…). **Schema thực tế KHÔNG như vậy** — chỉ Customer/Employee/Branch. Tài liệu này mô tả thực tế. Nên cập nhật `convention.md` cho khớp.

### 1.2 Tiền tệ

| Khía cạnh | Quy ước |
|---|---|
| Kiểu DB | `DECIMAL(18, 2)` cho **tất cả** cột tiền |
| JSON | **string** `"1000000.00"` — luôn đúng 2 chữ số lẻ. **Không** dùng `number` (mất chính xác float) |
| Backend (Java) | `BigDecimal` `setScale(2, HALF_UP)` |
| C++ | `class Money` giữ `int64_t` **đơn vị xu** (minor units), gắn `Currency` |
| Currency | Field **riêng**, mã từ lookup `Currency`: `USD | EUR | GBP | JPY | VND`. **Không có FX / quy đổi.** Mỗi transaction/loan/saving kế thừa currency của banking account nguồn |
| Làm tròn | **half-up** về 2 chữ số (khớp `CAST(... AS DECIMAL(18,2))` của T-SQL) |
| Cộng/trừ khác currency | **Cấm** — ném lỗi ở mọi tầng |

### 1.3 Lãi suất

- Lưu dạng **phần trăm/năm** trong `DECIMAL(18, 2)`, vd `5.00` = 5%/năm.
- JSON field: `annualInterestRatePct: "5.00"` (string, 2 chữ số lẻ).
- Chỉ 2 chữ số lẻ ⇒ **không** biểu diễn được 5.125%.
- Lãi tháng = `annual / 12 / 100`. Công thức trả góp (khớp `sp_loan_apply`):
  `M = P · r · (1+r)^n / ((1+r)^n − 1)`, với `r = 0` → `M = P / n`.
- Lãi tiết kiệm = **lãi đơn** (khớp `vw_SavingAccountDetails`):
  `interest = deposit · rate/100 · term_months/12`.

### 1.4 Ngày giờ

| Khía cạnh | Quy ước |
|---|---|
| Kiểu DB | `DATETIME` (không timezone, ~3ms) cho timestamp; `DATE` cho ngày |
| Timezone server | `Asia/Ho_Chi_Minh` — cấu hình JVM `-Duser.timezone=Asia/Ho_Chi_Minh`, SQL Server dùng giờ máy |
| JSON timestamp | ISO-8601 **không offset**: `"2026-09-07T14:30:00"` — hiểu là giờ server |
| JSON ngày | `"2026-09-07"` |
| Frontend | **Không** tự cộng/trừ offset; hiển thị nguyên như server trả |

### 1.5 Enum / lookup — giá trị chính xác (case-sensitive)

> Trích từ `database/src/schema/seeds/lookup.sql`. FE giữ map `value ↔ nhãn tiếng Việt`, **gửi lên đúng chuỗi gốc** (kể cả chuỗi có dấu cách như `"Loan Officer"`, `"On Leave"`, `"Verify Email"`).

| Lookup | Cột dùng | Giá trị hợp lệ |
|---|---|---|
| `AccountRole` | `Account.role` | `Admin`, `Customer`, `Employee` |
| `AccountStatus` | `Account.status` | `Pending`, `Active`, `Disabled`, `Locked` |
| `EmployeePosition` | `Employee.position` | `Manager`, `Teller`, `Loan Officer`, `Customer Service` |
| `EmployeeStatus` | `Employee.status` | `Active`, `On Leave`, `Resigned` |
| `BranchStatus` | `Branch.status` | `Active`, `Closed` |
| `BankingAccountType` | `BankingAccount.account_type` | `Savings`, `Checking`, `Business` |
| `BankingAccountStatus` | `BankingAccount.status` | `Active`, `Frozen`, `Closed` |
| `Currency` | `BankingAccount.currency` | `USD`, `EUR`, `GBP`, `JPY`, `VND` |
| `CardType` | `Card.card_type` | `Debit`, `Credit` |
| `CardStatus` | `Card.status` | `Active`, `Blocked`, `Expired` |
| `TransactionType` | `BankTransaction.transaction_type` | `Deposit`, `Withdrawal`, `Transfer`, `Payment`, `LoanDisbursement`, `LoanRepayment`, `SavingDeposit`, `SavingWithdrawal` |
| `TransactionStatus` | `BankTransaction.status` | `Pending`, `Successful`, `Canceled`, `Failed` |
| `LoanType` | `Loan.loan_type` | `Personal`, `Home`, `Auto`, `Education` |
| `LoanStatus` | `Loan.status` | `Pending`, `Approved`, `Rejected`, `Disbursed`, `Closed` |
| `SavingAccountStatus` | `SavingAccount.status` | `Active`, `Matured`, `Closed` |
| `NotificationType` | `Notification.title` | `System`, `Transaction`, `OTP` |
| `OTPPurpose` | `OTP.purpose` | `Login`, `Register`, `Transaction`, `Verify Email`, `PasswordReset` |
| `LoginHistoryStatus` | `LoginHistory.login_status` | `Successful`, `Failed` |
| (CHECK, không có bảng) | `Customer.gender`, `Employee.gender` | `Male`, `Female`, `Other` |

### 1.6 Response envelope

Stored proc trả về: **1..N dòng từ một `vw_*`** + cột `message` (hoặc `result_message`) ở cuối. Spring Boot chuẩn hoá lại:

**Thành công**
```json
{
  "success": true,
  "message": "Transfer successful.",
  "data": { "transactionId": 42, "amount": "1000000.00", "fee": "0.00", "...": "..." }
}
```
`data` là **object** cho create/update/get, **array** cho search/list.

**Thất bại**
```json
{
  "success": false,
  "message": "Insufficient balance or source account is not active.",
  "error": { "code": 250040, "domain": "bank_transaction" }
}
```

**Map HTTP status** (nguồn: `SqlErrorCatalog`, §3.2 + Phụ lục B):

| Tình huống | HTTP |
|---|---|
| Validate input sai (Bean Validation) | `400` |
| ID không tồn tại (`fn_*_validate_id = 0`) | `404` |
| Vi phạm quy tắc nghiệp vụ (số dư, trạng thái, trùng, sai state machine) | `409` |
| Sai giá trị enum / tham số ngoài miền | `422` |
| Khác | `500` |

- `error.code` = **đúng số `THROW`** của proc.
- `message` giữ nguyên tiếng Anh của proc; FE có thể hiển thị trực tiếp hoặc map theo `error.code`.

### 1.7 Casing & field mapping

- DB dùng `snake_case`; JSON/DTO dùng `camelCase`.
- Một tầng mapper **tường minh** trong Spring theo từng view (không auto). Ví dụ `vw_TransactionDetails`:

| Cột DB | Field JSON |
|---|---|
| `transaction_id` | `transactionId` |
| `from_bank_account_id` | `fromBankAccountId` |
| `masked_from_account_number` | `maskedFromAccountNumber` |
| `to_customer_id` | `toCustomerId` |
| `to_full_name` | `toFullName` |
| `amount`, `fee` | `amount`, `fee` (string tiền) |
| `transaction_type` | `transactionType` |
| `created_at` | `createdAt` |

### 1.8 Che dữ liệu nhạy cảm (masking)

- Các `vw_*Details` / `vw_*Summary` đã mask sẵn: email, phone, citizen_id, số tài khoản (`fn_mask_*`).
- ⚠️ **`card_number` KHÔNG được mask trong `vw_CardDetails`.** Contract:
  - API **phải mask thêm** `card_number` (`400000******1234`) ở mọi response, **trừ** response của `POST /api/cards` (phát hành) — hiện đầy đủ **đúng 1 lần**.
  - C++ port lại `fn_mask_bank_account_number` cho nhất quán.
- **Không bao giờ** trả ra client: `password_hash`, `cvv_hash`, `otp_code` (xem 1.10).

### 1.9 Phân trang & tìm kiếm

- Proc `*_search` trả **toàn bộ** dòng, không phân trang.
- Contract: Spring nhận query `?page=0&size=20&sort=createdAt,desc`, cắt trang **trong bộ nhớ**, trả:
  - body: `data` = array trang hiện tại
  - header: `X-Total-Count: <tổng>`
- Ngưỡng nâng cấp: khi một search trả > ~5.000 dòng, chuyển sang proc có `@offset/@fetch` (`OFFSET ... FETCH NEXT`). Chưa cần cho đồ án.

### 1.10 Xác thực & OTP

**DB không giữ** session / JWT / hash mật khẩu. Spring Boot sở hữu:

| Việc | Cách làm |
|---|---|
| Hash mật khẩu | **BCrypt** (`BCryptPasswordEncoder`). Proc lưu nguyên chuỗi truyền vào → **truyền hash BCrypt** vào `@password` của `sp_account_register` / `sp_account_change_password` / `sp_account_reset_password`. `sp_account_login` so khớp bằng `password_hash = @password` nên **login phải so ở tầng Spring**: đọc account, `passwordEncoder.matches(raw, hash)`, rồi (nếu cần) vẫn gọi `sp_account_login` với hash để lấy `vw_Account`. |
| JWT | Phát khi login OK (claims: `sub`=account_id, `role`, `username`). Verify bằng `JwtAuthFilter`. TTL 1h, refresh token 7 ngày (tuỳ chọn). |
| `LoginHistory` | **Spring gọi** `sp_login_history_create` sau mỗi lần login (thành công/thất bại) với `ip_address`, `device` từ request. |
| Khoá đăng nhập | Đếm số lần sai **phía Spring** (Redis hoặc bảng phụ) — DB không có cột. Sai ≥ 5 lần / 15 phút → `sp_admin_update_account_status` set `Locked` hoặc chặn tạm ở Spring. |
| OTP | `sp_otp_generate_otpcode` **trả `otp_code` plaintext trong result set**. Spring **KHÔNG** forward cho client. Gửi qua email/SMS (dev: ghi log). Response chỉ có `{ "otpId": ..., "expiresAt": ... }`. |

**Bug OTP replay (bắt buộc vá — §2.1 #2):** hiện `sp_otp_generate_otpcode` đánh dấu OTP cũ là `verified = 1`, và `fn_otp_validate_verify` chỉ kiểm "có 1 dòng `verified = 1` chưa hết hạn". ⇒ Sinh OTP lần 2 khiến `sp_account_activate` / `sp_account_reset_password` **qua được mà người dùng chưa nhập mã nào**.

### 1.11 Hợp đồng đồng thời (concurrency)

- Mọi thao tác chạm số dư **bắt buộc** dùng pattern *guarded UPDATE* (một câu lệnh, kiểm tra + trừ/cộng cùng lúc):
  ```sql
  UPDATE BankingAccount
  SET balance = balance - @x, available_balance = available_balance - @x
  WHERE bank_account_id = @id AND status = 'Active' AND available_balance >= @x;
  IF @@ROWCOUNT = 0 THROW <code>, '...', 1;
  ```
- **Cấm** `SELECT balance` rồi `UPDATE` (race condition).
- Spring: **luôn** qua `sp_*`, không tự viết SQL số dư.
- C++: `{call dbo.sp_*}` cho nghiệp vụ có proc; batch job chưa có proc thì viết guarded UPDATE y hệt và kiểm số dòng bị ảnh hưởng.

### 1.12 Mã lỗi — hai hệ đang tồn tại

T-SQL `THROW` yêu cầu số ≥ 50000. Hiện có 2 hệ:

| Hệ | Module | Bước nhảy |
|---|---|---|
| 6 chữ số | account (11xxxx–15xxxx), bank_transaction (21xxxx–27xxxx), banking_account (31xxxx–34xxxx), beneficiary (41xxxx–44xxxx), saving_account (35xxxx), notification (111xxx–114xxx) | `+10` |
| 6 chữ số, `+1` | login_history (101xxx–102xxx), otp (121xxx–122xxx) | `+1` |
| **5 chữ số** (chưa remap, vẫn ≥ 50000 nên chạy tốt) | branch (51xxx–56xxx), card (61xxx–64xxx), customer (71xxx–76xxx), employee (81xxx–87xxx), loan (91xxx–96xxx) | `+1` |

→ **`SqlErrorCatalog` phía Spring xử lý cả hai hệ** (Phụ lục B). Proc **mới** đặt mã theo chuẩn `MMSPCC` 6 chữ số, ≥ 50000 (xem memory *THROW error number range*). Không bắt buộc remap 5 chữ số cũ.

---

## 2. Tầng Database — sửa lỗi & bổ sung

> ✅ **17/17 bug đã sửa và verify** bằng `pwsh database/deploy.ps1 -Seed` (2026-09-07) → `DEPLOY OK` + `SEED OK`, và test tay 3 proc seed không chạm (`sp_bank_account_get_details`, `sp_card_get_details`, `sp_bank_transaction_search` với date range) + test OTP replay (`fn_otp_validate_verify` trả `0` sau khi sinh OTP 2 lần).
> `database/deploy.ps1` cũng đã viết lại (§2.4).
>
> ⚠️ Stored procedure có **deferred name resolution** → bug tham chiếu sai tên vẫn CREATE được lúc deploy, chỉ nổ khi EXEC. `DEPLOY OK` một mình **không** đủ — phải chạy `-Seed` + integration test.

### 2.1 Bug đã sửa

| # | Mức | File | Vấn đề → cách sửa |
|---|---|---|---|
| 1 | 🔴 Cao | `banking_account/bank_account_get_details.sql` | `FROM vw_BankingAccountDetails` (không tồn tại) → `vw_BankAccountDetails`; thêm `SET NOCOUNT ON`. |
| 2 | 🔴 Cao | `otp/otp_generate_otpcode.sql` | Vô hiệu OTP cũ bằng `SET verified = 1` (auth bypass) → đổi thành `SET expired_at = GETDATE()`. Chỉ `sp_otp_verify` mới được set `verified = 1`. |
| 3 | 🟠 TB | `bank_account_create.sql` ×2, `card_create.sql` ×2, `otp_generate_otpcode.sql` ×1 | `ABS(CHECKSUM(NEWID()))` tràn khi gặp INT.MIN → `ABS(CONVERT(BIGINT, CHECKSUM(NEWID())))` (5 chỗ). |
| 4 | 🟠 TB | `view/card.sql` + `card_get_details.sql` + `card_create.sql` | `vw_CardDetails.card_number` (PAN thô) → `masked_card_number`. `sp_card_get_details` đối chiếu qua `card_id`. `sp_card_create` trả `full_card_number` từ bảng `Card` — lộ đúng 1 lần. |
| 5 | 🟠 TB | `view/customer.sql` (`vw_CustomerStatistics`) | INNER JOIN + `SUM(balance)` nhân đôi → viết lại bằng 3 subquery, `FROM Customer C` không JOIN. |
| 6 | 🟠 TB | `schema/constraints.sql` | Thêm `UQ_Customer_Account UNIQUE(account_id)` + `UQ_Employee_Account UNIQUE(account_id)`. |
| 7 | 🟢 Thấp | `bank_transaction_search.sql` | `created_at >= DATEDIFF(DAY, 0, @from_date)` → `created_at >= @from_date` (rút gọn, cùng kết quả). |
| 8 | 🟢 Thấp | `view/bank_account.sql` (`vw_BankAccountDetails`) | Thêm `currency`, `available_balance`, `closed_at`. |
| 9 | 🟢 Thấp | `schema/defaults.sql` | `DF_Account_Status` `'Active'` → **`'Pending'`** (an toàn hơn cho luồng OTP). `DF_Account_UpdatedAt` giữ nguyên — chỉ là cosmetic và nhất quán 4 bảng. |
| 10 | 🟢 Thấp | `account/account_change_image.sql` | `dbo.ChangeAccountImage` → `dbo.sp_account_change_image`; mã lỗi `50030`→`160000`, `50031`→`160010`, `50032`→`160020`. |
| 11 | 🟢 Thấp | `schema/seeds/seed.sql` | (bạn đã sửa trước) phone phân biệt + mục Loan/Saving/Notification hoàn chỉnh. |
| 12 | 🟢 Thấp | `account_register.sql`, `account_login.sql`, `otp_verify.sql` | `SELECT` kết quả đưa ra **sau `COMMIT`**. `account_login` bỏ luôn `BEGIN/COMMIT TRANSACTION` (proc chỉ đọc). |
| 13 | 🟢 Thấp | `card/card_create.sql` | Thêm check `EXISTS(... AND status = 'Active')` → `THROW 61003` nếu TK không active. |
| 14 | 🟢 Thấp | `account/auth/account_reset_password.sql` | Thêm `IF fn_account_validate_status(@account_id,'Disabled') = 1 THROW 150015`. |
| 15 | 🟢 Thấp | `schema/constraints.sql` | Thêm `UQ_Beneficiary_Customer_BankAccount UNIQUE(customer_id, bank_account_id)`. |
| 16 | 🔵 Perf | `schema/indexes.sql` | Thêm `IX_OTP_Account_Purpose`, `IX_SavingAccount_Maturity(status, maturity_date)`, `IX_Loan_Customer_Status`. |
| 17 | ⚪ Vặt | `schema/sequences.sql` | Comment `BR000001` → `BR00000001`. |
| + | 🟢 Thấp | `banking_account/bank_account_update_status.sql` | `@bank_account_id INT` → `BIGINT` (nhất quán với mọi proc khác). |

### 2.2 SQL đã áp dụng (giữ lại làm bản ghi thay đổi)

**#1 — `bank_account_get_details.sql`** (sửa SELECT cuối proc):
```sql
SELECT *, 'Bank account retrieved successfully.' AS message
FROM vw_BankAccountDetails
WHERE bank_account_id = @bank_account_id;
```

**#2 — OTP replay (bản tối giản, KHÔNG thêm cột).** Chỉ sửa 1 chỗ trong `sp_otp_generate_otpcode` — cho OTP cũ **hết hạn** thay vì `verified = 1`:
```sql
-- Vô hiệu hoá OTP cũ cùng (account, purpose): cho HẾT HẠN, KHÔNG chạm 'verified'
UPDATE OTP
SET expired_at = GETDATE()
WHERE account_id = @account_id
    AND purpose = @purpose
    AND verified = 0
    AND expired_at > GETDATE();
```
Sau sửa: chỉ `sp_otp_verify` (người dùng nhập mã) mới set `verified = 1`, nên `fn_otp_validate_verify` thấy `verified = 1` là thật. `sp_account_activate` / `sp_account_reset_password` giữ nguyên `DELETE` OTP sau khi dùng → vẫn dùng-một-lần.
> Cột `consumed` chỉ cần khi làm **OTP xác thực chuyển tiền** ở Phase 7: lúc đó Spring gọi `sp_otp_verify` rồi mới gọi transfer — có cửa sổ 5 phút mà nếu Spring quên xoá OTP thì replay được. Khi tới đó: `ALTER TABLE OTP ADD consumed BIT NOT NULL DEFAULT 0`, thêm `AND consumed = 0` vào `fn_otp_validate_verify`, và một proc `sp_otp_consume(@account_id, @purpose)` cho Spring gọi sau giao dịch.

**#3 — tràn số `ABS(CHECKSUM(NEWID()))`** — trong `sp_bank_account_create`, `sp_card_create`, `sp_otp_generate_otpcode`, đổi **mọi** `ABS(CHECKSUM(NEWID()))` thành:
```sql
ABS(CONVERT(BIGINT, CHECKSUM(NEWID())))
```
`CHECKSUM` trả `int`; ép `bigint` **trước** rồi `ABS` thì không tràn khi gặp `-2147483648`.

**#4 — `vw_CardDetails`** đổi `C.card_number` thành:
```sql
dbo.fn_mask_bank_account_number(C.card_number) AS masked_card_number,
```
`sp_card_create` trả số thẻ đầy đủ **1 lần** bằng cách SELECT từ bảng `Card` trực tiếp (không qua view). `sp_card_get_details` đổi tham số nhận `@card_id BIGINT` (hoặc match 4 số cuối).

**#5 — `vw_CustomerStatistics`** viết lại bằng subquery (tránh nhân đôi + không loại khách):
```sql
CREATE OR ALTER VIEW vw_CustomerStatistics AS
SELECT
    C.customer_id, C.full_name, C.branch_id,
    (SELECT COUNT(*) FROM BankingAccount BA WHERE BA.customer_id = C.customer_id) AS total_bank_accounts,
    (SELECT COUNT(*) FROM Card CD
        JOIN BankingAccount BA ON CD.bank_account_id = BA.bank_account_id
        WHERE BA.customer_id = C.customer_id) AS total_cards,
    (SELECT ISNULL(SUM(BA.balance), 0) FROM BankingAccount BA WHERE BA.customer_id = C.customer_id) AS total_balance
FROM Customer C;
```

**#6 — UNIQUE "1 Account ↔ 1 hồ sơ"** (`schema/constraints.sql`, thêm vào phần UNIQUE):
```sql
ALTER TABLE Customer ADD CONSTRAINT UQ_Customer_Account UNIQUE(account_id);
ALTER TABLE Employee ADD CONSTRAINT UQ_Employee_Account UNIQUE(account_id);
```

**#7 — `bank_transaction_search.sql`** (rút gọn, cùng kết quả):
```sql
AND (@from_date IS NULL OR created_at >= @from_date)
AND (@to_date   IS NULL OR created_at <  DATEADD(DAY, 1, @to_date))
```

**#8 — `vw_BankAccountDetails`** thêm cột:
```sql
BA.available_balance,
BA.currency,
BA.closed_at,
```

**#10 — `account_change_image.sql`** (đổi tên proc + band mã lỗi):
```sql
DROP PROCEDURE IF EXISTS dbo.ChangeAccountImage;
GO
CREATE OR ALTER PROCEDURE dbo.sp_account_change_image
    @account_id BIGINT,
    @image_url  VARCHAR(2048)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            IF dbo.fn_account_validate_id(@account_id) = 0
                THROW 160000, 'Invalid account ID.', 1;
            IF dbo.fn_account_validate_status(@account_id, 'Active') = 0
                THROW 160010, 'Account is not active.', 1;
            UPDATE Account SET image_url = @image_url, updated_at = GETDATE()
            WHERE account_id = @account_id;
            IF @@ROWCOUNT = 0 THROW 160020, 'Failed to update account image.', 1;
        COMMIT TRANSACTION;
        SELECT account_id, image_url, GETDATE() AS updated_at,
               'Account image updated.' AS message
        FROM Account WHERE account_id = @account_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
```
`deploy.ps1` bước 5 quét `-Recurse` nên vẫn bắt được file này.

**#11 — `seed.sql`**: phone phân biệt (`0900000001`…`0900000004`); ghi chú `@password` là hash demo; viết nốt mục Loan:
```sql
DECLARE @khang_cif NCHAR(10) = (SELECT customer_id FROM Customer WHERE full_name = N'Huynh Bao Khang');
DECLARE @hao_emp   NCHAR(10) = (SELECT employee_id FROM Employee WHERE full_name = N'Vuong Nhat Hao');
DECLARE @khang_acc BIGINT   = (SELECT MIN(bank_account_id) FROM BankingAccount WHERE customer_id = @khang_cif);
EXEC dbo.sp_loan_apply    @customer_id=@khang_cif, @loan_type='Personal',
                          @loan_amount=20000000, @duration_months=12, @annual_interest_rate=12;
DECLARE @loan_id BIGINT = (SELECT MAX(loan_id) FROM Loan WHERE customer_id = @khang_cif);
EXEC dbo.sp_loan_review   @loan_id=@loan_id, @reviewer_id=@hao_emp, @decision='Approved';
EXEC dbo.sp_loan_disburse @customer_id=@khang_cif, @loan_id=@loan_id,
                          @bank_account_id=@khang_acc, @description=N'Disbursement';
```

**#16 — index tổ hợp** (`schema/indexes.sql`):
```sql
CREATE INDEX IX_OTP_Account_Purpose    ON OTP(account_id, purpose);
CREATE INDEX IX_SavingAccount_Maturity ON SavingAccount(status, maturity_date);
CREATE INDEX IX_Loan_Customer_Status   ON Loan(customer_id, status);
```

**#9, #12–#17 + fix INT→BIGINT** — đã áp dụng hết (xem bảng §2.1).

### 2.3 Procedure bổ sung

| Proc | File | Chữ ký | Mục đích | Mã lỗi | Trạng thái |
|---|---|---|---|---|---|
| `dbo.sp_admin_create_employee_account` | `account/admin_create_employee_account.sql` | `@username, @email, @phone_number, @password` | Admin tạo `Account` role `Employee` status `Active` (thay INSERT thẳng trong seed) | `170000`–`170030` | ✅ đã tạo + test |
| `dbo.sp_admin_update_account_status` | `account/admin_update_account_status.sql` | `@account_id BIGINT, @new_status VARCHAR(20)` | Lock / Disable / Enable account | `171000`–`171020` | ✅ đã tạo + test |
| ~~`dbo.sp_notification_list`~~ | — | — | **Bỏ** — `sp_notification_search(@account_id, NULL, 0, NULL, NULL)` đã làm "unread only", `(@account_id, NULL, NULL, NULL, NULL)` là "tất cả". YAGNI. | — | — |

> Bỏ `sp_loan_get_schedule` + bảng `LoanRepaymentSchedule` — để C++ `AmortizationSchedule` / Spring tính runtime từ `amount`, `interest_rate`, `duration_months`, `start_date`. YAGNI.

### 2.4 `deploy.ps1` — đã viết lại

`database/deploy.ps1` được tổ chức lại thành các khối rõ ràng, giữ mọi tính năng (`-Server`, `-User/-Password`, `-Docker`, `-Seed`) + thêm:
- **Preflight**: dừng ngay nếu không có `sqlcmd` trên PATH.
- **`Assert-Ok`** dùng chung: mọi bước (DROP, mỗi file, đếm object) fail → in lý do + `exit 1`.
- **Bước 5 (proc)**: `-Recurse` + `Sort-Object FullName`, loại `*\utils\*` → thứ tự nạp ổn định, bắt cả thư mục con.
- **Bước 6**: đếm `tables / views / procedures / functions` để kiểm chứng deploy "sạch".
- Header ghi rõ cảnh báo deferred name resolution + cách dùng từng tham số.

Thứ tự deploy **không đổi**: drop DB → `schema/{schema,lookup,constraints,defaults,indexes,sequences}.sql` → `schema/seeds/lookup.sql` → `common/*` → `<module>/utils/*` → `view/*` → `<module>/**` (proc) → đếm object → (nếu `-Seed`) `seed.sql`.

**Chạy:**
```bash
pwsh -File database/deploy.ps1            # deploy sạch, không seed
pwsh -File database/deploy.ps1 -Seed      # deploy + nạp demo data
pwsh -File database/deploy.ps1 -Docker -Seed
```
✅ Đã chạy `deploy.ps1 -Seed` ngày 2026-09-07: `DEPLOY OK` + `SEED OK`, seed dựng đủ 1 branch / 2 customer / 2 employee / 2 bank account / 1 card / 1 loan Disbursed / 1 saving / 1 notification.

---

## 3. Backend — Spring Boot

### 3.1 Cấu trúc package `com.bankingsystem`

```
config/       DataSourceConfig (mssql-jdbc), JacksonConfig (BigDecimal→string, date format),
              SecurityConfig (JWT filter chain), CorsConfig
security/     JwtService, JwtAuthFilter, AccountPrincipal, OwnershipGuard, PasswordConfig (BCrypt)
common/       ApiResponse<T>, ApiError, GlobalExceptionHandler, SqlErrorCatalog, PageMeta
db/           StoredProcedureExecutor, Rows (helper trim NCHAR + parse Timestamp/BigDecimal)
auth/         AuthController, AuthService
customer/     CustomerController, CustomerService
employee/     ...
branch/  bankingaccount/  card/  transaction/  loan/  saving/  beneficiary/  notification/
          loginhistory/  admin/
dto/          request/*  (record + Bean Validation)   response/*  (record camelCase mirror view)
```

**Không** có `@Entity` / JPA / repository interface — chỉ `StoredProcedureExecutor` + mapper.

### 3.2 Thành phần cốt lõi

**`ApiResponse` / `ApiError`**
```java
public record ApiResponse<T>(boolean success, String message, T data, ApiError error) {
    public static <T> ApiResponse<T> ok(String message, T data)      { return new ApiResponse<>(true,  message, data, null); }
    public static <T> ApiResponse<T> fail(String message, ApiError e) { return new ApiResponse<>(false, message, null, e);  }
}
public record ApiError(int code, String domain) {}
```

**`StoredProcedureExecutor`** — điểm tiếp xúc DUY NHẤT với `sp_*`
```java
@Component
public class StoredProcedureExecutor {
    private final JdbcTemplate jdbc;
    public StoredProcedureExecutor(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    /** Gọi {call dbo.<proc>(?, ?, ...)}; trả các dòng của result set đầu tiên. */
    public List<Map<String, Object>> call(String proc, Object... args) {
        String ph = args.length == 0 ? "" : String.join(", ", Collections.nCopies(args.length, "?"));
        String sql = "{call dbo." + proc + "(" + ph + ")}";
        return jdbc.execute((ConnectionCallback<List<Map<String, Object>>>) con -> {
            try (CallableStatement cs = con.prepareCall(sql)) {
                for (int i = 0; i < args.length; i++) cs.setObject(i + 1, args[i]);
                if (!cs.execute()) return List.of();
                try (ResultSet rs = cs.getResultSet()) { return Rows.toMaps(rs); }
            }
        });
    }
    public String message(Map<String, Object> row) {
        Object m = row.containsKey("message") ? row.get("message") : row.get("result_message");
        return m == null ? null : m.toString();
    }
}
```

**`SqlErrorCatalog`** — map mã `THROW` → (domain, HTTP). Dùng list khoảng vì hai hệ mã interleave (account 12xxxx vs otp 121xxx).
```java
public final class SqlErrorCatalog {
    public record Entry(String domain, HttpStatus status) {}
    private record Band(int lo, int hi, String domain, HttpStatus status) {}

    // Sắp theo lo; first-match. Đầy đủ dải ở Phụ lục B.
    private static final List<Band> BANDS = List.of(
        new Band( 51000,  56999, "branch",           HttpStatus.CONFLICT),
        new Band( 61000,  64999, "card",             HttpStatus.CONFLICT),
        new Band( 71000,  76999, "customer",         HttpStatus.CONFLICT),
        new Band( 81000,  87999, "employee",         HttpStatus.CONFLICT),
        new Band( 91000,  96999, "loan",             HttpStatus.CONFLICT),
        new Band(101000, 102999, "login_history",    HttpStatus.BAD_REQUEST),
        new Band(110000, 110999, "account",          HttpStatus.CONFLICT),
        new Band(111000, 114999, "notification",     HttpStatus.CONFLICT),
        new Band(120000, 120999, "account",          HttpStatus.CONFLICT),
        new Band(121000, 122999, "otp",              HttpStatus.UNPROCESSABLE_ENTITY),
        new Band(130000, 159999, "account",          HttpStatus.CONFLICT),
        new Band(160000, 179999, "admin",            HttpStatus.CONFLICT),
        new Band(210000, 279999, "bank_transaction", HttpStatus.CONFLICT),
        new Band(310000, 349999, "banking_account",  HttpStatus.CONFLICT),
        new Band(350000, 359999, "saving_account",   HttpStatus.CONFLICT),
        new Band(410000, 449999, "beneficiary",      HttpStatus.CONFLICT)
    );
    public static Entry lookup(int code) {
        if (code < 50000) return new Entry("system", HttpStatus.INTERNAL_SERVER_ERROR);
        return BANDS.stream().filter(b -> code >= b.lo() && code <= b.hi()).findFirst()
            .map(b -> new Entry(b.domain(), b.status()))
            .orElse(new Entry("business", HttpStatus.UNPROCESSABLE_ENTITY));
    }
    // "id không tồn tại" (mã kết thúc ...000 và message chứa "does not exist"/"Invalid") → override 404 ở handler
}
```

**`GlobalExceptionHandler`**
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ApiResponse<Void>> onSql(DataAccessException ex) {
        var sql = NestedExceptionUtils.getMostSpecificCause(ex);
        int code = (sql instanceof SQLException se) ? se.getErrorCode() : 0;
        var e = SqlErrorCatalog.lookup(code);
        String msg = stripThrowNoise(sql.getMessage());
        HttpStatus http = looksLikeNotFound(msg) ? HttpStatus.NOT_FOUND : e.status();
        return ResponseEntity.status(http).body(ApiResponse.fail(msg, new ApiError(code, e.domain())));
    }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> onValid(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
            .map(f -> f.getField() + ": " + f.getDefaultMessage()).collect(Collectors.joining("; "));
        return ResponseEntity.badRequest().body(ApiResponse.fail(msg, new ApiError(400, "validation")));
    }
}
```

**`JacksonConfig`** — tiền là string, ngày không offset
```java
@Bean Jackson2ObjectMapperBuilderCustomizer json() {
    return b -> {
        b.serializerByType(BigDecimal.class, new ToStringSerializer());
        b.simpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
        b.serializers(new LocalDateTimeSerializer(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")));
        b.serializers(new LocalDateSerializer(DateTimeFormatter.ISO_LOCAL_DATE));
    };
}
```

### 3.3 Hai ví dụ đầy đủ (mẫu để nhân bản)

**Branch — create** (`sp_branch_create` → `POST /api/branches`)
```java
@RestController @RequestMapping("/api/branches")
class BranchController {
    private final BranchService service;
    BranchController(BranchService s) { this.service = s; }

    @PostMapping @PreAuthorize("hasRole('ADMIN')")
    ApiResponse<BranchResponse> create(@Valid @RequestBody CreateBranchRequest req) {
        return service.create(req);
    }
}

record CreateBranchRequest(
    @NotBlank @Size(max = 100) String branchName,
    @NotBlank @Size(max = 100) String address,
    @NotBlank @Size(max = 20)  String phoneNumber) {}

record BranchResponse(String branchId, String branchName, String address,
                      String phoneNumber, String status,
                      LocalDateTime createdAt, LocalDateTime updatedAt) {}

@Service
class BranchService {
    private final StoredProcedureExecutor sp;
    BranchService(StoredProcedureExecutor sp) { this.sp = sp; }

    ApiResponse<BranchResponse> create(CreateBranchRequest r) {
        var rows = sp.call("sp_branch_create", r.branchName(), r.address(), r.phoneNumber());
        var row = rows.get(0);
        return ApiResponse.ok(sp.message(row), map(row));
    }
    private BranchResponse map(Map<String, Object> m) {
        return new BranchResponse(
            Rows.str(m, "branch_id"), Rows.str(m, "branch_name"), Rows.str(m, "address"),
            Rows.str(m, "phone_number"), Rows.str(m, "status"),
            Rows.dt(m, "created_at"), Rows.dt(m, "updated_at"));
    }
}
```

**Transaction — transfer** (`sp_bank_transaction_transfer` → `POST /api/transactions/transfer`)
```java
@PostMapping("/transfer") @PreAuthorize("hasRole('CUSTOMER')")
ApiResponse<TransactionResponse> transfer(@Valid @RequestBody TransferRequest req,
                                          @AuthenticationPrincipal AccountPrincipal me) {
    ownership.assertOwnsBankAccount(me, req.fromBankAccountId());   // TK nguồn phải của người đăng nhập
    var rows = sp.call("sp_bank_transaction_transfer",
        req.fromBankAccountId(), req.toBankAccountId(),
        req.amount(), req.fee() == null ? BigDecimal.ZERO : req.fee(), req.description());
    var row = rows.get(0);
    notifier.afterTransfer(row);                                    // §Phase 10: bắn Notification
    return ApiResponse.ok(sp.message(row), TransactionResponse.from(row));
}

record TransferRequest(
    @NotNull Long fromBankAccountId,
    @NotNull Long toBankAccountId,
    @NotNull @DecimalMin("0.01") BigDecimal amount,
    @DecimalMin("0.00") BigDecimal fee,
    @Size(max = 255) String description) {}
```

### 3.4 Quy tắc chung backend

- Mọi controller trả `ApiResponse<T>`.
- Validate input bằng annotation **trước** khi gọi proc (fail-fast, HTTP 400).
- **Không** `@Transactional` — proc tự `BEGIN/COMMIT/ROLLBACK`. Một request = một `sp.call`.
- Role check: `@PreAuthorize("hasRole('CUSTOMER'|'EMPLOYEE'|'ADMIN')")`; nghiệp vụ Loan review thêm check `position = 'Loan Officer'`.
- Ownership: `OwnershipGuard` — customer chỉ thao tác trên banking account / loan / saving / beneficiary của chính mình (query nhẹ qua `fn_*_validate_owner` hoặc view).
- Danh sách endpoint đầy đủ: **Phụ lục A**.

---

## 4. Frontend — React + TypeScript

### 4.1 Cấu trúc `src/`

```
api/          client.ts (axios + interceptor + unwrap envelope)
              authApi.ts, customerApi.ts, accountApi.ts, transactionApi.ts, loanApi.ts,
              savingApi.ts, cardApi.ts, beneficiaryApi.ts, notificationApi.ts, adminApi.ts
types/        models.ts (mirror response DTO), enums.ts (union chuỗi lookup + nhãn VN), money.ts
auth/         AuthContext.tsx, useAuth.ts, ProtectedRoute.tsx, RoleGuard.tsx
              pages/ Login, Register, OtpVerify, ForgotPassword, ResetPassword
pages/        (Customer)  Dashboard, Accounts, AccountDetail, OpenAccount, Transfer,
                          TransactionHistory, Cards, IssueCard, Loans, LoanApply, LoanDetail,
                          Savings, OpenSaving, Beneficiaries, Notifications, Profile
              (Employee)  CustomerLookup, CustomerProfile, LoanReviewQueue, BranchDesk
              (Admin)     AccountsAdmin, Employees, Branches, Stats
components/    MoneyInput, MoneyDisplay, EnumSelect, DataTable, StatusBadge, OtpInput,
              FormField, ConfirmDialog, MaskedValue, Pagination
hooks/        useApi.ts, usePagination.ts   (React Query cho server state)
lib/          format.ts (ngày/tiền/mask), validation.ts (zod schema mirror CHECK constraint)
routes.tsx    App.tsx   main.tsx
```

State: **React Query** (server cache) + **AuthContext** (session). **Không Redux.**

### 4.2 Nguyên tắc chống xung đột

- `types/models.ts` viết **thủ công theo §1** (hoặc sinh từ OpenAPI của Spring bằng `openapi-typescript`).
- **Mọi** số tiền đi qua `money.ts`; **mọi** enum đi qua `enums.ts`; **mọi** ngày qua `format.ts`. Không component nào tự `parseFloat` / `new Date()` trực tiếp trên dữ liệu API.
- Form validation (`validation.ts`) mirror đúng ràng buộc DB + validate của proc (`amount > 0`, `gender ∈ {Male,Female,Other}`, `duration_months > 0`, …).

### 4.3 Lõi

**`api/client.ts`**
```ts
import axios from "axios";

export const http = axios.create({ baseURL: import.meta.env.VITE_API_URL ?? "/api" });

http.interceptors.request.use((cfg) => {
  const t = localStorage.getItem("jwt");
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

export interface Envelope<T> {
  success: boolean;
  message: string;
  data: T | null;
  error: { code: number; domain: string } | null;
}

export class ApiError extends Error {
  constructor(readonly code: number, readonly domain: string, message: string) { super(message); }
}

export async function unwrap<T>(p: Promise<{ data: Envelope<T> }>): Promise<T> {
  const { data: env } = await p;
  if (!env.success || env.data === null)
    throw new ApiError(env.error?.code ?? 0, env.error?.domain ?? "unknown", env.message);
  return env.data;
}
```

**`types/money.ts`**
```ts
// §1.2: tiền là chuỗi "1000000.00" (2 chữ số lẻ). KHÔNG dùng number để tính toán.
export type MoneyString = string;
const SYMBOL: Record<string, string> = { VND: "₫", USD: "$", EUR: "€", GBP: "£", JPY: "¥" };

export function parseMinor(s: MoneyString): bigint {
  const neg = s.startsWith("-");
  const [w, f = "00"] = (neg ? s.slice(1) : s).split(".");
  return (neg ? -1n : 1n) * (BigInt(w) * 100n + BigInt((f + "00").slice(0, 2)));
}

export function formatMoney(s: MoneyString, currency: string): string {
  const minor = parseMinor(s);
  const neg = minor < 0n;
  const abs = neg ? -minor : minor;
  const grouped = (abs / 100n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  const cents = (abs % 100n).toString().padStart(2, "0");
  const body = currency === "VND" || currency === "JPY" ? grouped : `${grouped},${cents}`;
  return `${neg ? "-" : ""}${body} ${SYMBOL[currency] ?? currency}`;
}

// Ô nhập "1.000.000" / "1000000,5" -> "1000000.50" trước khi gửi
export function toMoneyString(input: string): MoneyString {
  const n = Number(input.replace(/[.\s]/g, "").replace(",", "."));
  if (!isFinite(n) || n < 0) throw new Error("Số tiền không hợp lệ");
  return n.toFixed(2);
}
```

**`types/enums.ts`**
```ts
// §1.5 — chuỗi PHẢI khớp lookup seed, kể cả dấu cách.
export const ACCOUNT_STATUS   = ["Pending", "Active", "Disabled", "Locked"] as const;
export const BANK_ACC_STATUS  = ["Active", "Frozen", "Closed"] as const;
export const TRANSACTION_TYPE = ["Deposit","Withdrawal","Transfer","Payment",
  "LoanDisbursement","LoanRepayment","SavingDeposit","SavingWithdrawal"] as const;
export const LOAN_STATUS      = ["Pending","Approved","Rejected","Disbursed","Closed"] as const;
export const CURRENCY         = ["USD","EUR","GBP","JPY","VND"] as const;

export type AccountStatus   = (typeof ACCOUNT_STATUS)[number];
export type TransactionType = (typeof TRANSACTION_TYPE)[number];
export type LoanStatus      = (typeof LOAN_STATUS)[number];

// nhãn hiển thị — CHỈ để render, KHÔNG gửi lên
export const LABEL_VI: Record<string, string> = {
  Pending: "Chờ xử lý", Active: "Hoạt động", Disabled: "Vô hiệu", Locked: "Đã khoá",
  Frozen: "Đóng băng", Closed: "Đã đóng",
  Deposit: "Nạp tiền", Withdrawal: "Rút tiền", Transfer: "Chuyển khoản", Payment: "Thanh toán",
  LoanDisbursement: "Giải ngân", LoanRepayment: "Trả nợ vay",
  SavingDeposit: "Gửi tiết kiệm", SavingWithdrawal: "Rút tiết kiệm",
  Approved: "Đã duyệt", Rejected: "Từ chối", Disbursed: "Đã giải ngân",
};
```

**`api/transactionApi.ts`** (mẫu)
```ts
import { http, unwrap } from "./client";
import type { TransactionDetail, Page } from "../types/models";

export const transactionApi = {
  transfer: (body: {
    fromBankAccountId: number; toBankAccountId: number;
    amount: string; fee?: string; description?: string;
  }) => unwrap<TransactionDetail>(http.post("/transactions/transfer", body)),

  deposit: (body: { bankAccountId: number; amount: string; description?: string }) =>
    unwrap<TransactionDetail>(http.post("/transactions/deposit", body)),

  history: (bankAccountId: number, page = 0, size = 20) =>
    unwrap<Page<TransactionDetail>>(
      http.get("/transactions", { params: { bankAccountId, page, size, sort: "createdAt,desc" } })),
};
```

### 4.4 Component chính

| Component | Vai trò |
|---|---|
| `MoneyInput` | ô nhập tiền, tự format nhóm nghìn khi blur, `onChange` trả `MoneyString` chuẩn |
| `MoneyDisplay` | render `formatMoney(value, currency)` |
| `EnumSelect` | dropdown từ mảng enum + `LABEL_VI`, value = chuỗi gốc |
| `DataTable` | bảng + sort + phân trang server (`X-Total-Count`) |
| `StatusBadge` | badge màu theo status (Active=xanh, Frozen/Locked=vàng, Closed/Rejected=đỏ…) |
| `OtpInput` | 6 ô nhập 1 chữ số, auto-advance, submit khi đủ 6 |
| `MaskedValue` | hiện giá trị đã mask + nút 👁 gọi API "reveal" (nếu có quyền) |
| `ConfirmDialog` | xác nhận cho hành động không đảo ngược (chuyển tiền, đóng TK, huỷ thẻ) |

- Bảng "màn hình → API + role + form": **Phụ lục C**.

---

## 5. C++ Core — code OOP nghiệp vụ ngân hàng

> Namespace `banking`. Build **CMake** (C++17). Kết nối SQL Server qua **nanodbc** (wrapper ODBC gọn, MIT). Test: `assert` thuần (không framework).
> Vai trò: mô hình domain OOP giàu (Money, Loan, Saving, Card, state machine) + đồng bộ DB. **Ghi qua `sp_*`**; batch job chưa có proc thì tự chạy guarded UPDATE.

### 5.1 Cấu trúc thư mục

```
cpp/
  CMakeLists.txt
  include/banking/
    currency.hpp  money.hpp  enums.hpp  exceptions.hpp  masking.hpp
    banking_account.hpp  card.hpp  luhn.hpp  loan.hpp  saving_account.hpp  otp.hpp
    infra/db.hpp  infra/banking_account_repository.hpp
    app/transfer_service.hpp
  src/
    domain/  money.cpp  card.cpp  masking.cpp
    infra/   db.cpp  banking_account_repository.cpp
    app/     transfer_service.cpp
    jobs/    settle_matured_savings.cpp  mark_overdue_loans.cpp
    cli/     main.cpp
  tests/     run_tests.cpp
```

### 5.2 `include/banking/currency.hpp`

```cpp
#pragma once
#include <string>
#include <stdexcept>

namespace banking {

enum class Currency { USD, EUR, GBP, JPY, VND };

inline std::string to_code(Currency c) {
    switch (c) {
        case Currency::USD: return "USD"; case Currency::EUR: return "EUR";
        case Currency::GBP: return "GBP"; case Currency::JPY: return "JPY";
        case Currency::VND: return "VND";
    }
    throw std::logic_error("bad Currency");
}

inline Currency currency_from_code(const std::string& s) {
    if (s == "USD") return Currency::USD;
    if (s == "EUR") return Currency::EUR;
    if (s == "GBP") return Currency::GBP;
    if (s == "JPY") return Currency::JPY;
    if (s == "VND") return Currency::VND;
    throw std::invalid_argument("Unknown currency code: " + s);
}

} // namespace banking
```

### 5.3 `include/banking/exceptions.hpp`

```cpp
#pragma once
#include <stdexcept>
#include <string>

namespace banking {

// Base cho mọi lỗi nghiệp vụ. code khớp band THROW của stored procedure (§1.12 + Phụ lục B),
// để tầng trên map sang HTTP / thông báo GIỐNG HỆT Spring Boot.
class DomainException : public std::runtime_error {
public:
    DomainException(int code, const std::string& msg) : std::runtime_error(msg), code_(code) {}
    int code() const noexcept { return code_; }
private:
    int code_;
};

struct ValidationException     : DomainException { using DomainException::DomainException; };
struct NotFoundException       : DomainException { using DomainException::DomainException; };
struct IllegalStateTransition  : DomainException { using DomainException::DomainException; };

struct InsufficientFundsException : DomainException {
    InsufficientFundsException()
        : DomainException(250040, "Insufficient balance or source account is not active.") {}
};
struct AccountNotActiveException : DomainException {
    explicit AccountNotActiveException(int code = 250050)
        : DomainException(code, "Account is not active.") {}
};

} // namespace banking
```

### 5.4 `include/banking/money.hpp` + `src/domain/money.cpp`

```cpp
// money.hpp
#pragma once
#include <cstdint>
#include <string>
#include "banking/currency.hpp"
#include "banking/exceptions.hpp"

namespace banking {

// Giá trị tiền cố định 2 chữ số thập phân (khớp DECIMAL(18,2)), lưu theo "xu".
// Bất biến: luôn gắn 1 Currency; toán tử giữa 2 Money khác currency -> ném ValidationException.
class Money {
public:
    Money() = default;
    Money(std::int64_t minor, Currency ccy) : minor_(minor), ccy_(ccy) {}
    static Money zero(Currency ccy) { return Money(0, ccy); }

    static Money parse(const std::string& s, Currency ccy);   // "1000000" | "1000000.00"
    std::string  to_string() const;                            // luôn "…​.dd"

    std::int64_t minor() const { return minor_; }
    Currency currency() const { return ccy_; }
    bool is_zero() const { return minor_ == 0; }
    bool is_negative() const { return minor_ < 0; }

    Money operator+(const Money& o) const { same(o); return {minor_ + o.minor_, ccy_}; }
    Money operator-(const Money& o) const { same(o); return {minor_ - o.minor_, ccy_}; }
    Money operator-() const { return {-minor_, ccy_}; }

    bool operator==(const Money& o) const { return ccy_ == o.ccy_ && minor_ == o.minor_; }
    bool operator!=(const Money& o) const { return !(*this == o); }
    bool operator<(const Money& o)  const { same(o); return minor_ <  o.minor_; }
    bool operator<=(const Money& o) const { same(o); return minor_ <= o.minor_; }
    bool operator>(const Money& o)  const { same(o); return minor_ >  o.minor_; }
    bool operator>=(const Money& o) const { same(o); return minor_ >= o.minor_; }

    // Nhân hệ số thực (lãi suất), làm tròn half-up về xu.
    Money scaled(double factor) const;

private:
    void same(const Money& o) const {
        if (ccy_ != o.ccy_) throw ValidationException(900001, "Currency mismatch in Money operation");
    }
    std::int64_t minor_ = 0;
    Currency ccy_ = Currency::VND;
};

} // namespace banking
```

```cpp
// src/domain/money.cpp
#include "banking/money.hpp"
#include <cmath>

namespace banking {

Money Money::parse(const std::string& s, Currency ccy) {
    if (s.empty()) throw ValidationException(900002, "Empty money string");
    std::size_t i = 0;
    bool neg = (s[i] == '-');
    if (neg) ++i;
    std::int64_t whole = 0; bool anyDigit = false;
    for (; i < s.size() && s[i] != '.'; ++i) {
        if (s[i] < '0' || s[i] > '9') throw ValidationException(900002, "Invalid money: " + s);
        whole = whole * 10 + (s[i] - '0'); anyDigit = true;
    }
    std::int64_t frac = 0; int fd = 0;
    if (i < s.size() && s[i] == '.') {
        for (++i; i < s.size(); ++i) {
            if (s[i] < '0' || s[i] > '9') throw ValidationException(900002, "Invalid money: " + s);
            if (fd == 2) throw ValidationException(900003, "Money supports at most 2 decimals: " + s);
            frac = frac * 10 + (s[i] - '0'); ++fd;
        }
    }
    if (!anyDigit) throw ValidationException(900002, "Invalid money: " + s);
    while (fd < 2) { frac *= 10; ++fd; }
    std::int64_t minor = whole * 100 + frac;
    return Money(neg ? -minor : minor, ccy);
}

std::string Money::to_string() const {
    std::int64_t v = minor_ < 0 ? -minor_ : minor_;
    std::string out = (minor_ < 0 ? "-" : "");
    out += std::to_string(v / 100) + ".";
    std::int64_t f = v % 100;
    if (f < 10) out += "0";
    out += std::to_string(f);
    return out;
}

Money Money::scaled(double factor) const {
    double raw = static_cast<double>(minor_) * factor;
    std::int64_t r = static_cast<std::int64_t>(raw >= 0 ? std::floor(raw + 0.5) : std::ceil(raw - 0.5));
    return Money(r, ccy_);
}

} // namespace banking
```

### 5.5 `include/banking/enums.hpp`

```cpp
#pragma once
#include <string>
#include <stdexcept>

namespace banking {

enum class AccountRole          { Admin, Customer, Employee };
enum class AccountStatus        { Pending, Active, Disabled, Locked };
enum class EmployeePosition     { Manager, Teller, LoanOfficer, CustomerService };
enum class BankingAccountType   { Savings, Checking, Business };
enum class BankingAccountStatus { Active, Frozen, Closed };
enum class CardType             { Debit, Credit };
enum class CardStatus           { Active, Blocked, Expired };
enum class TransactionType      { Deposit, Withdrawal, Transfer, Payment,
                                  LoanDisbursement, LoanRepayment, SavingDeposit, SavingWithdrawal };
enum class TransactionStatus    { Pending, Successful, Canceled, Failed };
enum class LoanType             { Personal, Home, Auto, Education };
enum class LoanStatus           { Pending, Approved, Rejected, Disbursed, Closed };
enum class SavingStatus         { Active, Matured, Closed };
enum class OtpPurpose           { Login, Register, Transaction, VerifyEmail, PasswordReset };

// --- chuỗi để nói chuyện với DB/API: PHẢI khớp lookup seed (§1.5) ---
inline const char* db_str(BankingAccountStatus s) {
    switch (s) { case BankingAccountStatus::Active: return "Active";
                 case BankingAccountStatus::Frozen: return "Frozen";
                 case BankingAccountStatus::Closed: return "Closed"; }
    throw std::logic_error("bad BankingAccountStatus");
}
inline const char* db_str(TransactionType t) {
    switch (t) {
        case TransactionType::Deposit:          return "Deposit";
        case TransactionType::Withdrawal:       return "Withdrawal";
        case TransactionType::Transfer:         return "Transfer";
        case TransactionType::Payment:          return "Payment";
        case TransactionType::LoanDisbursement: return "LoanDisbursement";
        case TransactionType::LoanRepayment:    return "LoanRepayment";
        case TransactionType::SavingDeposit:    return "SavingDeposit";
        case TransactionType::SavingWithdrawal: return "SavingWithdrawal";
    }
    throw std::logic_error("bad TransactionType");
}
inline const char* db_str(EmployeePosition p) {
    switch (p) {
        case EmployeePosition::Manager:         return "Manager";
        case EmployeePosition::Teller:          return "Teller";
        case EmployeePosition::LoanOfficer:     return "Loan Officer";      // dấu cách!
        case EmployeePosition::CustomerService: return "Customer Service";  // dấu cách!
    }
    throw std::logic_error("bad EmployeePosition");
}
inline const char* db_str(OtpPurpose p) {
    switch (p) {
        case OtpPurpose::Login:         return "Login";
        case OtpPurpose::Register:      return "Register";
        case OtpPurpose::Transaction:   return "Transaction";
        case OtpPurpose::VerifyEmail:   return "Verify Email";              // dấu cách!
        case OtpPurpose::PasswordReset: return "PasswordReset";
    }
    throw std::logic_error("bad OtpPurpose");
}

} // namespace banking
```

### 5.6 `include/banking/banking_account.hpp`

```cpp
#pragma once
#include <string>
#include "banking/money.hpp"
#include "banking/enums.hpp"
#include "banking/exceptions.hpp"

namespace banking {

// Bản sao trong RAM của một dòng BankingAccount. Các method dưới đây ép ĐÚNG bất biến
// mà CK_BankingAccount_Balance + guarded UPDATE của DB áp:
//   0 <= available_balance <= balance   và chỉ thao tác khi status == Active.
// Đây là nơi C++ "sở hữu" quy tắc; khi PERSIST vẫn gọi sp_* (xem repository).
class BankingAccount {
public:
    BankingAccount(long long id, std::string customerId, std::string number,
                   Money balance, Money available,
                   BankingAccountType type, BankingAccountStatus status)
        : id_(id), customerId_(std::move(customerId)), number_(std::move(number)),
          balance_(balance), available_(available), type_(type), status_(status) {
        enforce_invariant(310099);
    }

    long long id() const { return id_; }
    const std::string& customer_id() const { return customerId_; }
    const std::string& number() const { return number_; }
    Money balance() const { return balance_; }
    Money available_balance() const { return available_; }
    BankingAccountStatus status() const { return status_; }

    void require_active(int code) const {
        if (status_ != BankingAccountStatus::Active) throw AccountNotActiveException(code);
    }

    void deposit(const Money& amount) {                 // khớp sp_bank_transaction_deposit
        require_positive(amount, 210010);
        require_active(210020);
        balance_   = balance_   + amount;
        available_ = available_ + amount;
        enforce_invariant(210099);
    }

    void debit_for(const Money& amount, const Money& fee) {   // khớp guarded debit của transfer
        require_positive(amount, 250030);
        require_active(250050);
        Money total = amount + fee;
        if (available_ < total) throw InsufficientFundsException();
        balance_   = balance_   - total;
        available_ = available_ - total;
        enforce_invariant(250099);
    }

    void credit(const Money& amount) {                  // khớp guarded credit
        require_positive(amount, 250030);
        require_active(250050);
        balance_   = balance_   + amount;
        available_ = available_ + amount;
        enforce_invariant(250099);
    }

private:
    static void require_positive(const Money& m, int code) {
        if (m.is_zero() || m.is_negative())
            throw ValidationException(code, "Amount must be greater than 0.");
    }
    void enforce_invariant(int code) const {
        if (balance_.is_negative() || available_.is_negative() || available_ > balance_)
            throw DomainException(code, "BankingAccount balance invariant violated");
    }

    long long id_;
    std::string customerId_, number_;
    Money balance_, available_;
    BankingAccountType type_;
    BankingAccountStatus status_;
};

} // namespace banking
```

### 5.7 `include/banking/luhn.hpp` + `include/banking/card.hpp`

```cpp
// luhn.hpp — khớp dbo.fn_luhn_check_digit (nhân đôi từ phải sang)
#pragma once
#include <string>
#include <stdexcept>

namespace banking {

struct Luhn {
    static char check_digit(const std::string& partial) {   // partial = số CHƯA có check digit
        int sum = 0; bool dbl = true;
        for (auto it = partial.rbegin(); it != partial.rend(); ++it) {
            if (*it < '0' || *it > '9') throw std::invalid_argument("Luhn: non-digit");
            int d = *it - '0';
            if (dbl) { d *= 2; if (d > 9) d -= 9; }
            sum += d; dbl = !dbl;
        }
        return static_cast<char>('0' + (10 - sum % 10) % 10);
    }
    static bool validate(const std::string& full) {
        return full.size() >= 2 &&
               check_digit(full.substr(0, full.size() - 1)) == full.back();
    }
};

} // namespace banking
```

```cpp
// card.hpp — khớp sp_card_create: 16 số = BIN(6) + 9 random + Luhn(1); BIN Debit=400000 / Credit=520000
#pragma once
#include <string>
#include <random>
#include "banking/enums.hpp"
#include "banking/luhn.hpp"

namespace banking {

class Card {
public:
    static Card issue(long long bankAccountId, CardType type) {
        std::string bin  = (type == CardType::Debit) ? "400000" : "520000";
        std::string body = bin + random_digits(9);
        std::string number = body + std::string(1, Luhn::check_digit(body));
        return Card(bankAccountId, number, type, sha256_hex(random_digits(3)));
    }
    const std::string& number()   const { return number_; }
    const std::string& cvv_hash() const { return cvvHash_; }
    CardType type() const { return type_; }

private:
    Card(long long acc, std::string num, CardType t, std::string cvvHash)
        : bankAccountId_(acc), number_(std::move(num)), type_(t), cvvHash_(std::move(cvvHash)) {}

    static std::string random_digits(int n) {
        static std::mt19937_64 rng{std::random_device{}()};
        std::uniform_int_distribution<int> d(0, 9);
        std::string s; s.reserve(n);
        for (int i = 0; i < n; ++i) s += static_cast<char>('0' + d(rng));
        return s;
    }
    static std::string sha256_hex(const std::string& in);  // dùng picosha2.h (header-only), src/domain/card.cpp

    long long bankAccountId_;
    std::string number_;
    CardType type_;
    std::string cvvHash_;
};

} // namespace banking
```

### 5.8 `include/banking/loan.hpp` (+ AmortizationSchedule)

```cpp
#pragma once
#include <vector>
#include <cmath>
#include "banking/money.hpp"
#include "banking/enums.hpp"
#include "banking/exceptions.hpp"

namespace banking {

struct AmortRow {
    int   period;
    Money payment, principal, interest, balance;   // balance = dư nợ sau kỳ này
};

class AmortizationSchedule {
public:
    // KHỚP sp_loan_apply: r = annual_pct/12/100 ; M = P·r·(1+r)^n / ((1+r)^n − 1) ; r==0 → P/n
    static Money monthly_payment(const Money& principal, double annual_pct, int months) {
        if (months <= 0) throw ValidationException(91003, "Duration must be greater than zero.");
        double r = annual_pct / 12.0 / 100.0;
        if (r == 0.0) return Money(principal.minor() / months, principal.currency());
        double p  = static_cast<double>(principal.minor());
        double pw = std::pow(1.0 + r, months);
        double m  = p * r * pw / (pw - 1.0);
        return Money(static_cast<long long>(std::floor(m + 0.5)), principal.currency());
    }

    static std::vector<AmortRow> build(const Money& principal, double annual_pct, int months) {
        std::vector<AmortRow> rows;
        Money pay = monthly_payment(principal, annual_pct, months);
        double r  = annual_pct / 12.0 / 100.0;
        Money bal = principal;
        for (int k = 1; k <= months; ++k) {
            Money interest      = bal.scaled(r);
            Money principalPart = pay - interest;
            if (k == months) {                       // kỳ cuối nuốt phần lẻ -> dư nợ về 0
                principalPart = bal;
                pay = principalPart + interest;
            }
            bal = bal - principalPart;
            rows.push_back({k, pay, principalPart, interest, bal});
        }
        return rows;
    }
};

// State machine khớp Loan: Pending → Approved/Rejected → Disbursed → Closed
class Loan {
public:
    Loan(long long id, std::string customerId, LoanType type, Money amount,
         double annualPct, int months, Money remaining, LoanStatus status)
        : id_(id), customerId_(std::move(customerId)), type_(type), amount_(amount),
          annualPct_(annualPct), months_(months), remaining_(remaining), status_(status) {}

    Money monthly_payment() const { return AmortizationSchedule::monthly_payment(amount_, annualPct_, months_); }
    std::vector<AmortRow> schedule() const { return AmortizationSchedule::build(amount_, annualPct_, months_); }

    void review(bool approved, const std::string& officerId) {
        if (status_ != LoanStatus::Pending)
            throw IllegalStateTransition(95004, "Loan is not pending review.");
        status_ = approved ? LoanStatus::Approved : LoanStatus::Rejected;
        approvedBy_ = officerId;
    }
    void mark_disbursed() {
        if (status_ != LoanStatus::Approved)
            throw IllegalStateTransition(92004, "Loan is not approved.");
        status_ = LoanStatus::Disbursed;
        remaining_ = amount_;
    }
    // Trả nợ: kẹp theo dư nợ, tự Closed khi về 0 (khớp sp_loan_repay)
    Money apply_repayment(const Money& amount) {
        if (status_ != LoanStatus::Disbursed)
            throw IllegalStateTransition(94005, "Loan is not in disbursed state.");
        Money pay = (amount < remaining_) ? amount : remaining_;
        remaining_ = remaining_ - pay;
        if (remaining_.is_zero()) status_ = LoanStatus::Closed;
        return pay;
    }

    long long id() const { return id_; }
    LoanStatus status() const { return status_; }
    Money remaining_balance() const { return remaining_; }

private:
    long long id_;
    std::string customerId_, approvedBy_;
    LoanType type_;
    Money amount_, remaining_;
    double annualPct_;
    int months_;
    LoanStatus status_;
};

} // namespace banking
```

### 5.9 `include/banking/saving_account.hpp`

```cpp
#pragma once
#include "banking/money.hpp"
#include "banking/enums.hpp"

namespace banking {

// Khớp vw_SavingAccountDetails + sp_saving_account_close:
//   projected_interest = deposit · rate/100 · term_months/12   (lãi ĐƠN)
//   maturity_amount    = deposit + projected_interest
//   Tất toán TRƯỚC hạn -> lãi = 0, chỉ trả gốc.
class SavingAccount {
public:
    SavingAccount(long long id, long long sourceBankAccountId, Money deposit,
                  double annualRatePct, int termMonths, SavingStatus status)
        : id_(id), source_(sourceBankAccountId), deposit_(deposit),
          ratePct_(annualRatePct), term_(termMonths), status_(status) {}

    Money projected_interest() const {
        return deposit_.scaled(ratePct_ / 100.0 * static_cast<double>(term_) / 12.0);
    }
    Money maturity_amount() const { return deposit_ + projected_interest(); }
    Money settlement_amount(bool matured) const { return matured ? maturity_amount() : deposit_; }

    long long id() const { return id_; }
    long long source_bank_account_id() const { return source_; }
    Money deposit_amount() const { return deposit_; }
    SavingStatus status() const { return status_; }

private:
    long long id_, source_;
    Money deposit_;
    double ratePct_;
    int term_;
    SavingStatus status_;
};

} // namespace banking
```

### 5.10 `include/banking/infra/db.hpp` (nanodbc RAII)

```cpp
#pragma once
#include <string>
#include <nanodbc/nanodbc.h>
#include "banking/exceptions.hpp"

namespace banking {

// RAII: một kết nối ODBC tới BankingSystem. Chuỗi kết nối Windows-auth:
//   "Driver={ODBC Driver 17 for SQL Server};Server=localhost\\SQLEXPRESS01;
//    Database=BankingSystem;Trusted_Connection=yes;"
class Db {
public:
    explicit Db(const std::string& connStr) : conn_(NANODBC_TEXT(connStr)) {}
    nanodbc::connection& raw() { return conn_; }

    // Trích mã THROW của SQL Server từ database_error (chuỗi "... (NNNNNN) (SQLExecute)").
    static int extract_sql_code(const nanodbc::database_error& e);
private:
    nanodbc::connection conn_;
};

// RAII transaction: commit khi gọi commit(); rollback tự động nếu hủy trước khi commit.
class Transaction {
public:
    explicit Transaction(Db& db) : tx_(db.raw()) {}
    void commit() { tx_.commit(); }
private:
    nanodbc::transaction tx_;
};

} // namespace banking
```

### 5.11 `include/banking/infra/banking_account_repository.hpp` + `.cpp`

```cpp
// banking_account_repository.hpp
#pragma once
#include <optional>
#include "banking/infra/db.hpp"
#include "banking/banking_account.hpp"
#include "banking/money.hpp"

namespace banking {

class BankingAccountRepository {
public:
    explicit BankingAccountRepository(Db& db) : db_(db) {}

    std::optional<BankingAccount> find_by_id(long long id);

    // GHI luôn qua stored procedure => cùng một bản cài đặt quy tắc với Spring Boot.
    long long transfer(long long fromId, long long toId,
                       const Money& amount, const Money& fee, const std::string& description);
private:
    Db& db_;
};

} // namespace banking
```

```cpp
// src/infra/banking_account_repository.cpp
#include "banking/infra/banking_account_repository.hpp"

namespace banking {

std::optional<BankingAccount> BankingAccountRepository::find_by_id(long long id) {
    nanodbc::statement st(db_.raw());
    nanodbc::prepare(st, NANODBC_TEXT(
        "SELECT bank_account_id, customer_id, bank_account_number, balance, available_balance, "
        "       account_type, currency, status "
        "FROM BankingAccount WHERE bank_account_id = ?"));
    st.bind(0, &id);
    auto r = nanodbc::execute(st);
    if (!r.next()) return std::nullopt;

    Currency ccy = currency_from_code(trim(r.get<std::string>("currency")));
    auto money = [&](const char* col) {
        return Money::parse(r.get<std::string>(col), ccy);   // ODBC trả DECIMAL dạng chuỗi
    };
    BankingAccountStatus status = parse_bank_status(trim(r.get<std::string>("status")));
    return BankingAccount(
        r.get<long long>("bank_account_id"),
        trim(r.get<std::string>("customer_id")),          // NCHAR(10) -> trim
        trim(r.get<std::string>("bank_account_number")),
        money("balance"), money("available_balance"),
        parse_bank_type(trim(r.get<std::string>("account_type"))),
        status);
}

long long BankingAccountRepository::transfer(long long fromId, long long toId,
        const Money& amount, const Money& fee, const std::string& description) {
    try {
        nanodbc::statement st(db_.raw());
        nanodbc::prepare(st, NANODBC_TEXT(
            "{call dbo.sp_bank_transaction_transfer(?, ?, ?, ?, ?)}"));
        std::string a = amount.to_string(), f = fee.to_string();
        st.bind(0, &fromId);
        st.bind(1, &toId);
        st.bind(2, a.c_str());
        st.bind(3, f.c_str());
        if (description.empty()) st.bind_null(4); else st.bind(4, description.c_str());
        auto r = nanodbc::execute(st);
        if (r.next()) return r.get<long long>("transaction_id");
        throw DomainException(250090, "Transfer returned no row");
    } catch (const nanodbc::database_error& e) {
        int code = Db::extract_sql_code(e);
        throw DomainException(code ? code : 250000, e.what());  // giữ nguyên mã THROW của proc
    }
}

} // namespace banking
```

### 5.12 `include/banking/app/transfer_service.hpp`

```cpp
#pragma once
#include "banking/infra/banking_account_repository.hpp"

namespace banking {

// Use-case chuyển tiền. Kiểm tra sơ bộ bằng domain object cho thông báo thân thiện + fail-fast,
// rồi ủy quyền cho sp_bank_transaction_transfer (nguồn sự thật + chống đua).
class TransferService {
public:
    explicit TransferService(Db& db) : repo_(db) {}
    struct Result { long long transactionId; };

    Result execute(long long fromId, long long toId,
                   const Money& amount, const Money& fee, const std::string& description) {
        if (fromId == toId)
            throw ValidationException(250020, "Source and destination accounts must be different.");
        if (amount.is_zero() || amount.is_negative())
            throw ValidationException(250030, "Amount must be greater than 0.");

        auto from = repo_.find_by_id(fromId);
        if (!from) throw NotFoundException(250000, "Source bank account does not exist.");
        auto to = repo_.find_by_id(toId);
        if (!to)   throw NotFoundException(250010, "Destination bank account does not exist.");

        from->debit_for(amount, fee);   // mô phỏng cục bộ -> bắt lỗi sớm; DB vẫn quyết định cuối
        to->credit(amount);

        return { repo_.transfer(fromId, toId, amount, fee, description) };
    }
private:
    BankingAccountRepository repo_;
};

} // namespace banking
```

### 5.13 `src/jobs/settle_matured_savings.cpp` (job — C++ tự sở hữu logic)

```cpp
#include "banking/infra/db.hpp"

namespace banking::jobs {

// Tương đương dbo.sp_saving_account_settle_matured — chạy theo lịch (cron/Task Scheduler).
// Đây là chỗ C++ "làm logic" trực tiếp: guarded UPDATE, kiểm số dòng.
int settle_matured_savings(Db& db) {
    nanodbc::statement st(db.raw());
    nanodbc::prepare(st, NANODBC_TEXT(
        "UPDATE SavingAccount SET status = 'Matured' "
        "WHERE status = 'Active' AND maturity_date <= CAST(GETDATE() AS DATE)"));
    nanodbc::execute(st);
    return static_cast<int>(st.affected_rows());
}

} // namespace banking::jobs
```

### 5.14 `tests/run_tests.cpp`

```cpp
#include <cassert>
#include <iostream>
#include "banking/money.hpp"
#include "banking/luhn.hpp"
#include "banking/loan.hpp"
#include "banking/saving_account.hpp"
#include "banking/banking_account.hpp"
using namespace banking;

static void test_money() {
    auto a = Money::parse("1000000.00", Currency::VND);
    auto b = Money::parse("250000.50",  Currency::VND);
    assert((a + b).to_string() == "1250000.50");
    assert((a - b).to_string() == "749999.50");
    assert(a > b);
    bool threw = false;
    try { (void)(a + Money::parse("1.00", Currency::USD)); } catch (const ValidationException&) { threw = true; }
    assert(threw);
    threw = false;
    try { (void)Money::parse("1.234", Currency::VND); } catch (const ValidationException&) { threw = true; }
    assert(threw);
}

static void test_luhn() {
    assert(Luhn::validate("4000000000000002"));
    std::string body = "400000123456789";
    assert(Luhn::validate(body + std::string(1, Luhn::check_digit(body))));
}

static void test_amortization() {
    auto principal = Money::parse("12000000.00", Currency::VND);
    auto rows = AmortizationSchedule::build(principal, 12.0, 12);
    assert(rows.size() == 12);
    Money sum = Money::zero(Currency::VND);
    for (auto& r : rows) sum = sum + r.principal;
    assert(sum == principal);              // tổng phần gốc == vốn vay
    assert(rows.back().balance.is_zero()); // dư nợ kỳ cuối == 0
}

static void test_saving() {
    auto dep = Money::parse("10000000.00", Currency::VND);
    SavingAccount s(1, 1, dep, 6.0, 12, SavingStatus::Active);
    assert(s.projected_interest().to_string() == "600000.00");
    assert(s.settlement_amount(false) == dep);
    assert(s.settlement_amount(true).to_string() == "10600000.00");
}

static void test_banking_account() {
    auto z = Money::zero(Currency::VND);
    BankingAccount acc(1, "CIF0000001", "0001", z, z,
                       BankingAccountType::Checking, BankingAccountStatus::Active);
    acc.deposit(Money::parse("1000000.00", Currency::VND));
    assert(acc.available_balance().to_string() == "1000000.00");
    bool threw = false;
    try { acc.debit_for(Money::parse("2000000.00", Currency::VND), z); }
    catch (const InsufficientFundsException&) { threw = true; }
    assert(threw);
}

static void test_loan_state_machine() {
    Loan l(1, "CIF0000001", LoanType::Personal, Money::parse("20000000.00", Currency::VND),
           12.0, 12, Money::zero(Currency::VND), LoanStatus::Pending);
    l.review(true, "EMP0000001");
    l.mark_disbursed();
    auto paid = l.apply_repayment(Money::parse("25000000.00", Currency::VND));  // trả dư
    assert(paid.to_string() == "20000000.00");
    assert(l.status() == LoanStatus::Closed);
}

int main() {
    test_money();
    test_luhn();
    test_amortization();
    test_saving();
    test_banking_account();
    test_loan_state_machine();
    std::cout << "All C++ core tests passed\n";
}
```

### 5.15 `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.20)
project(banking_core LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(nanodbc
    GIT_REPOSITORY https://github.com/nanodbc/nanodbc.git
    GIT_TAG        v2.14.0)
set(NANODBC_DISABLE_TESTS ON  CACHE BOOL "" FORCE)
set(NANODBC_DISABLE_EXAMPLES ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(nanodbc)

add_library(banking_domain
    src/domain/money.cpp
    src/domain/card.cpp
    src/domain/masking.cpp)
target_include_directories(banking_domain PUBLIC include)

add_library(banking_infra
    src/infra/db.cpp
    src/infra/banking_account_repository.cpp
    src/app/transfer_service.cpp
    src/jobs/settle_matured_savings.cpp
    src/jobs/mark_overdue_loans.cpp)
target_link_libraries(banking_infra PUBLIC banking_domain nanodbc)

add_executable(banking_cli src/cli/main.cpp)
target_link_libraries(banking_cli PRIVATE banking_infra)

enable_testing()
add_executable(core_tests tests/run_tests.cpp
    src/domain/money.cpp src/domain/card.cpp src/domain/masking.cpp)
target_include_directories(core_tests PRIVATE include)
add_test(NAME core_tests COMMAND core_tests)
```

### 5.16 `src/cli/main.cpp` (rút gọn)

```cpp
#include <iostream>
#include "banking/infra/db.hpp"
#include "banking/app/transfer_service.hpp"
namespace banking::jobs { int settle_matured_savings(Db&); }

int main() {
    using namespace banking;
    const std::string conn =
        "Driver={ODBC Driver 17 for SQL Server};"
        "Server=localhost\\SQLEXPRESS01;Database=BankingSystem;Trusted_Connection=yes;";
    try {
        Db db(conn);
        std::cout << "== Banking core CLI ==\n"
                     " 1) Chuyen tien\n 2) Chay job dao han so tiet kiem\n 0) Thoat\n> ";
        int c; std::cin >> c;
        if (c == 1) {
            long long from, to; std::string amt;
            std::cout << "Tu TK id: ";  std::cin >> from;
            std::cout << "Toi TK id: "; std::cin >> to;
            std::cout << "So tien: ";   std::cin >> amt;
            TransferService svc(db);
            auto res = svc.execute(from, to, Money::parse(amt, Currency::VND),
                                   Money::zero(Currency::VND), "CLI transfer");
            std::cout << "OK, transaction_id = " << res.transactionId << "\n";
        } else if (c == 2) {
            std::cout << "Da dao han " << jobs::settle_matured_savings(db) << " so.\n";
        }
    } catch (const DomainException& e) {
        std::cerr << "Loi [" << e.code() << "]: " << e.what() << "\n";
        return 1;
    }
}
```

### 5.17 Ràng buộc "không xung đột" cho C++ (checklist)

- [ ] `Money` luôn 2 chữ số + half-up; toán tử khác currency → ném.
- [ ] `enums.hpp::db_str` copy **đúng** chuỗi §1.5 (chú ý `"Loan Officer"`, `"Customer Service"`, `"On Leave"`, `"Verify Email"`).
- [ ] Mọi ghi số dư qua `sp_*`; job chưa có proc → guarded UPDATE + kiểm `affected_rows()`.
- [ ] `DomainException::code()` khớp band DB (Phụ lục B) — để CLI/tầng trên map lỗi giống Spring.
- [ ] Đọc `NCHAR(10)` (`customer_id`, `employee_id`, `branch_id`) phải `trim()`.
- [ ] Đọc `DECIMAL` từ ODBC dưới dạng chuỗi rồi `Money::parse` (tránh double).

---

## 6. Thứ tự thực hiện (Roadmap)

| Phase | Nội dung | Xong khi |
|---|---|---|
| **0** | ✅ Xong: 17 bug DB + `deploy.ps1` (`DEPLOY OK` + `SEED OK`). Còn lại: 3 proc bổ sung §2.3 (`sp_admin_*`, `sp_notification_list`) — làm ở Phase 3/11 | — |
| **1** | Chốt §1 (contract) với cả nhóm. Tạo repo `backend/`, `frontend/`, `cpp/` | Contract được review, 3 skeleton build rỗng chạy được |
| **2** | Spring skeleton: `DataSourceConfig`, `StoredProcedureExecutor`, `ApiResponse`, `GlobalExceptionHandler`, `SqlErrorCatalog`, `JacksonConfig`; 1 lát cắt dọc `sp_branch_create` → `POST /api/branches` + integration test | 1 endpoint end-to-end xanh |
| **3** | Auth: register → OTP → activate → login (JWT) → `/me`; BCrypt; Spring ghi `LoginHistory`. FE: trang Login/Register/OtpVerify + `AuthContext` + `ProtectedRoute` | Đăng ký + đăng nhập thật, token hoạt động |
| **4** | C++ nền: CMake + nanodbc, `Money`, `Currency`, `exceptions`, `enums`, `Db`/`Transaction`, `BankingAccountRepository::find_by_id`, `run_tests.cpp` | `ctest` xanh; CLI kết nối DB + in số dư 1 TK |
| **5** | Customer / Employee / Branch CRUD: Spring endpoints + React pages + C++ entity/repo | 3 module CRUD đủ trên cả 3 tầng |
| **6** | BankingAccount + Card: mở/đóng/freeze TK, phát hành/khoá thẻ. C++ `BankingAccount` invariant + `Card::issue` + `Luhn` test. FE: OpenAccount, Cards, IssueCard | Mở TK + phát thẻ (số thẻ pass Luhn) |
| **7** | **Transactions** (trọng yếu về đồng thời): deposit/withdraw/transfer/payment. C++ `TransferService` + `BankingAccountRepository::transfer`. FE: Transfer + TransactionHistory | Test 20 lệnh chuyển song song vượt số dư → đúng phần được phép thành công, `available_balance ≥ 0` |
| **8** | Loan: apply/review/disburse/repay. C++ `Loan` + `AmortizationSchedule` + test. FE: LoanApply, LoanDetail (bảng trả góp), Employee `LoanReviewQueue` | Vòng đời khoản vay đủ; lịch trả góp FE = C++ = công thức proc |
| **9** | Saving: open/close/settle-matured. C++ `SavingAccount` + `settle_matured_savings` job. FE: Savings, OpenSaving | Mở + tất toán (đúng hạn & trước hạn); job đổi status `Matured` |
| **10** | Beneficiary + Notification. Spring bắn `sp_notification_create` sau khi transfer/loan thành công (best-effort, không rollback nghiệp vụ nếu notify lỗi) | Chuyển tiền xong nhận thông báo |
| **11** | Admin + Dashboard: `sp_admin_update_account_status`, `vw_CustomerStatistics` (đã sửa), trang Stats | Admin khoá/mở account; dashboard hiện số liệu |
| **12** | Hardening: gửi OTP qua email thật, rate-limit + khoá đăng nhập, `/security-review`, load test transfer, CI (`deploy.ps1` + `mvn test` + `ctest` + `npm run build && npm test`) | CI xanh toàn bộ |

---

## 7. Kiểm thử (Verification)

**Database** — ✅ đã chạy 2026-09-07
```bash
pwsh -File database/deploy.ps1 -Seed
# DEPLOY OK + SEED OK; 1 branch, 2 customer, 2 employee, 2 bank account, 1 card, 1 loan Disbursed, 1 saving, 1 notification
```
Smoke test 30 case (search/get toàn bộ module + 2 proc admin mới): **30/30 PASS**, mã lỗi 170000/171010 đúng band.

**Backend (Spring)**
```bash
cd backend && mvn test
# integration test trỏ DB test (dựng bằng chính deploy.ps1 trong @BeforeAll hoặc Testcontainers mssql)
```
Kịch bản tối thiểu: `POST /api/branches` (201 + envelope) · register→otp→activate→login (JWT hợp lệ) · transfer thiếu số dư → 409 + `error.code = 250040`.

**C++ core**
```bash
cd cpp && cmake -B build && cmake --build build && ctest --test-dir build --output-on-failure
# kỳ vọng: "All C++ core tests passed"
```

**Frontend**
```bash
cd frontend && npm run build && npm test
```
Kịch bản tay: register → nhập OTP (lấy từ log dev) → login → mở TK → nạp 1.000.000 → chuyển 200.000 sang TK khác → xem lịch sử thấy 2 giao dịch; apply loan → (đăng nhập Loan Officer) duyệt → giải ngân → trả góp 1 kỳ; mở sổ tiết kiệm → tất toán trước hạn (chỉ nhận gốc).

**Kiểm tra đồng thời (bắt buộc — Phase 7)**
```
TK A có 1.000.000. Bắn song song 20 lệnh transfer 100.000 (tổng 2.000.000) từ A.
Kỳ vọng: đúng 10 lệnh Successful, 10 lệnh lỗi 250040; A.available_balance = 0, không âm;
tổng credit vào các TK đích = 1.000.000.
```

---

## Phụ lục A — Bảng endpoint đầy đủ

> `role`: C = Customer, E = Employee, LO = Loan Officer, A = Admin, `-` = public. Response `data` là DTO camelCase mirror view tương ứng (§1.7).

### Auth (`/api/auth`)
| Method | Path | Proc | Role | Request | Response |
|---|---|---|---|---|---|
| POST | `/register` | `sp_account_register` | - | `{username,email,phoneNumber,password}` | `AccountView` |
| POST | `/otp` | `sp_otp_generate_otpcode` | - | `{accountId,purpose}` | `{otpId,expiresAt}` (KHÔNG trả code) |
| POST | `/otp/verify` | `sp_otp_verify` | - | `{accountId,otpCode,purpose}` | `AccountView` |
| POST | `/activate` | `sp_account_activate` | - | `{accountId}` | `AccountView` |
| POST | `/login` | `sp_account_login` (+ BCrypt + JWT + `sp_login_history_create`) | - | `{username,password}` | `{token,account:AccountView}` |
| POST | `/password/change` | `sp_account_change_password` | C/E/A | `{oldPassword,newPassword}` | `{accountId,updatedAt}` |
| POST | `/password/reset` | `sp_account_reset_password` | - | `{accountId,newPassword}` (sau khi verify OTP `PasswordReset`) | `{accountId,updatedAt}` |
| GET | `/me` | — (đọc JWT + `vw_Account`) | C/E/A | — | `AccountView` |
| PUT | `/me/image` | `sp_account_change_image` | C/E/A | `{imageUrl}` | `{accountId,imageUrl,updatedAt}` |

### Customer (`/api/customers`)
| Method | Path | Proc | Role |
|---|---|---|---|
| POST | `` | `sp_create_customer_profile` | C (sau activate) |
| GET | `/me` | `sp_customer_get_profile` | C |
| PUT | `/me` | `sp_customer_update_profile` | C |
| GET | `/{customerId}/summary` | `sp_customer_get_summary` | E/A |
| GET | `?citizenId=&fullName=` | `sp_customer_search` | E/A |
| GET | `/statistics` | `vw_CustomerStatistics` | A |
| PUT | `/{customerId}/branch` | `sp_customer_assign_branch` | E/A |

### Employee (`/api/employees`)
`POST ``` `sp_employee_create_profile` (A) · `GET /me` `sp_employee_get_profile` (E) · `PUT /me` `sp_employee_update_profile` (E) · `PUT /{id}/position` `sp_employee_update_position` (A) · `PUT /{id}/status` `sp_employee_update_status` (A) · `PUT /{id}/branch` `sp_employee_assign_branch` (A) · `GET ?citizenId=&fullName=` `sp_employee_search` (A)

### Branch (`/api/branches`)
`POST ``` `sp_branch_create` (A) · `PUT /{id}` `sp_branch_update` (A) · `PUT /{id}/status` `sp_branch_update_status` (A) · `GET /{id}` `sp_branch_get_info` (E/A) · `GET /{id}/summary` `sp_branch_get_summary` (E/A) · `GET ?name=&status=` `sp_branch_search` (E/A)

### Banking Account (`/api/banking-accounts`)
`POST ``` `sp_bank_account_create` (C) · `GET /{id}` `sp_bank_account_get_details` (C owner / E) · `GET ?number=&customerId=&type=&status=` `sp_bank_account_search` (E/A; C chỉ của mình) · `PUT /{id}/status` `sp_bank_account_update_status` (E/A)

### Card (`/api/cards`)
`POST ``` `sp_card_create` (C owner của banking account) → **response duy nhất hiện `cardNumber` đầy đủ** · `GET /{cardNumber}` `sp_card_get_details` (C owner / E) · `GET ?bankAccountId=&type=&status=` `sp_card_search` (C owner / E) · `PUT /{cardId}/status` `sp_card_update_status` (C owner / E)

### Transaction (`/api/transactions`)
`POST /deposit` `sp_bank_transaction_deposit` (E teller / C tự nạp demo) · `POST /withdraw` `sp_bank_transaction_withdraw` (C owner) · `POST /transfer` `sp_bank_transaction_transfer` (C owner nguồn) · `POST /payment` `sp_bank_transaction_payment` (C owner nguồn) · `GET /{id}` `sp_bank_transaction_get_details` (C liên quan / E) · `GET ?bankAccountId=&type=&status=&fromDate=&toDate=` `sp_bank_transaction_search` (C owner / E) · `PUT /{id}/status` `sp_bank_transaction_update_status` (E/A)

### Loan (`/api/loans`)
`POST ``` `sp_loan_apply` (C) · `PUT /{id}/review` `sp_loan_review` (LO) · `POST /{id}/disburse` `sp_loan_disburse` (LO/E) · `POST /{id}/repay` `sp_loan_repay` (C owner) · `GET /{id}` `sp_loan_get_details` (C owner / E) · `GET ?customerId=&type=&status=&approvedBy=&fromDate=&toDate=` `sp_loan_search` (E/LO; C chỉ của mình) · `GET /{id}/schedule` — (tính runtime từ `vw_LoanDetails`)

### Saving (`/api/savings`)
`POST ``` `sp_saving_account_open` (C) · `POST /{id}/close` `sp_saving_account_close` (C owner) · `GET /{id}` `sp_saving_account_get_details` (C owner / E) · `GET ?customerId=&status=&fromDate=&toDate=` `sp_saving_account_search` (E; C của mình) · `POST /settle-matured` `sp_saving_account_settle_matured` (A / job)

### Beneficiary (`/api/beneficiaries`)
`POST ``` `sp_beneficiary_create` (C) · `PUT /{id}` `sp_beneficiary_update` (C owner) · `GET /{id}` `sp_beneficiary_get_details` (C owner) · `GET ?name=` `sp_beneficiary_search` (C)

### Notification (`/api/notifications`)
`GET ?onlyUnread=` `sp_notification_list` (C/E owner) · `GET /{id}` `sp_notification_get_details` (owner) · `PUT /{id}/read` `sp_notification_mark_is_read` (owner) · *(internal)* `sp_notification_create` — gọi từ service khác, không expose

### Login History (`/api/login-history`)
`GET ?loginStatus=&ip=&device=&fromDate=&toDate=` `sp_login_history_search` (C của mình / A)

### Admin (`/api/admin`)
`POST /employee-accounts` `sp_admin_create_employee_account` (A) · `PUT /accounts/{id}/status` `sp_admin_update_account_status` (A)

---

## Phụ lục B — Bảng mã lỗi theo procedure

> Dùng để nạp `SqlErrorCatalog` và `DomainException` (C++). Mã đầu dải thường = "id không tồn tại" → map HTTP **404**; mã cuối dải = "UPDATE/INSERT ảnh hưởng 0 dòng" (vi phạm quy tắc) → **409**.

| Procedure | Dải mã | Domain |
|---|---|---|
| `sp_account_activate` | 110000, 110010, 110020 | account |
| `sp_account_change_password` | 120000–120030 | account |
| `sp_account_login` | 130000, 130010, 130020 | account |
| `sp_account_register` | 140000–140030 | account |
| `sp_account_reset_password` | 150000, 150010, 150020 | account |
| `sp_account_change_image` *(mới)* | 160000, 160010, 160020 | admin/account |
| `sp_admin_create_employee_account` *(mới)* | 170000–170030 | admin |
| `sp_admin_update_account_status` *(mới)* | 171000–171020 | admin |
| `sp_notification_list` *(mới)* | 172000 | notification |
| `sp_login_history_create` / `_search` | 101000–101002 / 102000–102002 | login_history |
| `sp_notification_create/_get/_mark/_search` | 111000–111030 / 112000 / 113000–113020 / 114000–114020 | notification |
| `sp_otp_generate_otpcode` / `sp_otp_verify` | 121000–121002 / 122000–122002 | otp |
| `sp_bank_transaction_deposit` / `_withdraw` | 210000–210020 / 270000–270020 | bank_transaction |
| `sp_bank_transaction_get_details` / `_payment` / `_search` / `_transfer` / `_update_status` | 220000 / 230000–230050 / 240000–240030 / 250000–250050 / 260000–260020 | bank_transaction |
| `sp_bank_account_create/get/search/update_status` | 310000–310030 / 320000 / 330000–330020 / 340000–340020 | banking_account |
| `sp_saving_account_open/get/search/close` | 350000–350070 / 351000–351010 / 352000–352030 / 353000–353040 | saving_account |
| `sp_beneficiary_create/get/search/update` | 410000–410040 / 420000 / 430000 / 440000–440020 | beneficiary |
| `sp_branch_create/get_summary/get_info/search/update_status/update` | 51000–51003 / 52000 / 53000 / 54000 / 55000–55002 / 56000–56001 | branch |
| `sp_card_create/get/search/update_status` | 61000–61002 / 62000 / 63000–63002 / 64000–64002 | card |
| `sp_customer_assign_branch/create_profile/get_profile/get_summary/search/update_profile` | 71000–71004 / 72000–72006 / 73000–73001 / 74000 / 75000 / 76000–76005 | customer |
| `sp_employee_assign_branch/create_profile/get_profile/search/update_position/update_profile/update_status` | 81000–81004 / 82000–82007 / 83000–83001 / 84000 / 85000–85003 / 86000–86003 / 87000–87003 | employee |
| `sp_loan_apply/disburse/get_details/repay/review/search` | 91000–91006 / 92000–92006 / 93000–93001 / 94000–94007 / 95000–95004 / 96000–96005 | loan |
| C++ nội bộ (không từ DB) | 900001–900003 (Money) | system |

---

## Phụ lục C — Màn hình frontend → API

| Màn hình | Role | Gọi API | Form / field chính | Validate (mirror DB) |
|---|---|---|---|---|
| Register | - | `POST /auth/register` → `POST /auth/otp` | username, email, phone, password, confirm | email regex; phone 9–20 số; password ≥ 8 |
| OtpVerify | - | `POST /auth/otp/verify` → `POST /auth/activate` | 6 ô OTP | đúng 6 chữ số |
| Login | - | `POST /auth/login` | username, password | non-empty |
| ForgotPassword / ResetPassword | - | `POST /auth/otp` (`PasswordReset`) → `/otp/verify` → `/password/reset` | email/username, OTP, newPassword | password ≥ 8 |
| CreateProfile | C | `POST /customers` | fullName, dob, gender, citizenId, address, branchId | gender ∈ {Male,Female,Other}; dob ≤ hôm nay; citizenId 9–20 số |
| Dashboard | C | `GET /banking-accounts?customerId=me`, `GET /notifications?onlyUnread=1` | — | — |
| OpenAccount | C | `POST /banking-accounts` | accountType, currency | type ∈ BankingAccountType; currency ∈ Currency |
| AccountDetail | C | `GET /banking-accounts/{id}`, `GET /transactions?bankAccountId=` | — | — |
| Transfer | C | `POST /transactions/transfer` | fromBankAccountId, toBankAccountId / beneficiary, amount, fee, description | amount > 0; from ≠ to; amount+fee ≤ availableBalance (cảnh báo mềm) |
| TransactionHistory | C | `GET /transactions?bankAccountId=&type=&status=&fromDate=&toDate=` (paged) | filter | fromDate ≤ toDate |
| Cards / IssueCard | C | `GET /cards?bankAccountId=`, `POST /cards` | cardType | type ∈ CardType |
| LoanApply | C | `POST /loans` | loanType, amount, durationMonths, annualInterestRatePct | tất cả > 0; type ∈ LoanType |
| LoanDetail | C | `GET /loans/{id}`, `GET /loans/{id}/schedule`, `POST /loans/{id}/repay` | repay amount | amount > 0 |
| OpenSaving / Savings | C | `POST /savings`, `GET /savings?customerId=me`, `POST /savings/{id}/close` | sourceBankAccountId, depositAmount, termMonths, interestRate | deposit > 0; term > 0; rate ≥ 0 |
| Beneficiaries | C | `GET/POST/PUT /beneficiaries` | beneficiaryName, bankAccountId, bankName | không phải TK của chính mình |
| Notifications | C/E | `GET /notifications`, `PUT /notifications/{id}/read` | — | — |
| Profile | C/E | `GET/PUT /customers/me` \| `/employees/me`, `PUT /auth/me/image` | — | — |
| CustomerLookup / CustomerProfile | E | `GET /customers?citizenId=&fullName=`, `GET /customers/{id}/summary` | search | ≥ 1 tiêu chí |
| LoanReviewQueue | LO | `GET /loans?status=Pending`, `PUT /loans/{id}/review`, `POST /loans/{id}/disburse` | decision ∈ {Approved,Rejected} | — |
| AccountsAdmin | A | `PUT /admin/accounts/{id}/status` | newStatus | status ∈ AccountStatus |
| Employees | A | `POST /admin/employee-accounts` → `POST /employees`, `PUT /employees/{id}/*` | — | position ∈ EmployeePosition |
| Branches | A | `GET/POST/PUT /branches` | branchName, address, phone | non-empty |
| Stats | A | `GET /customers/statistics`, `GET /branches/{id}/summary` | — | — |

---

## Ghi chú kết

- File C++ trong §5 sẵn sàng tách thành cây thư mục ở §5.1. `masking.cpp`, `db.cpp` (hàm `extract_sql_code`, `trim`, `parse_*`), `card.cpp` (`sha256_hex` dùng `picosha2.h`), `mark_overdue_loans.cpp` viết theo cùng khuôn mẫu đã cho.
- SQL sửa DB (§2) là **snippet để chép tay** vào file `.sql` tương ứng, không ghi đè tự động.
- Không viết sẵn cả 60 controller — dùng 2 mẫu §3.3 nhân bản theo Phụ lục A.
- Mọi thay đổi phải giữ `database/deploy.ps1` chạy ra `DEPLOY OK` (xem memory *Clean deploy workflow*).
