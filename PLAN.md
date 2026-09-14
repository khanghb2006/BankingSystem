# PLAN.md — Kế hoạch triển khai Banking System

> Tài liệu này là hợp đồng làm việc chung cho 3 tầng: **SQL Server (đã có)** → **ASP.NET Core API (C#)** → **React + TypeScript**.
> Mọi con số / định dạng / tên gọi phải theo đúng **§1 Hợp đồng chuẩn dùng chung** để frontend và backend không xung đột.

---

## Mục lục

- [0. Tổng quan & kiến trúc](#0-tổng-quan--kiến-trúc)
- [1. Hợp đồng chuẩn dùng chung (Shared Contract)](#1-hợp-đồng-chuẩn-dùng-chung-shared-contract)
- [2. Tầng Database — bổ sung](#2-tầng-database--bổ-sung)
- [3. Backend — ASP.NET Core](#3-backend--aspnet-core)
- [4. Frontend — React + TypeScript](#4-frontend--react--typescript)
- [5. Thứ tự thực hiện (Roadmap)](#5-thứ-tự-thực-hiện-roadmap)
- [6. Kiểm thử (Verification)](#6-kiểm-thử-verification)
- [Phụ lục A — Bảng endpoint đầy đủ](#phụ-lục-a--bảng-endpoint-đầy-đủ)
- [Phụ lục B — Bảng mã lỗi theo procedure](#phụ-lục-b--bảng-mã-lỗi-theo-procedure)
- [Phụ lục C — Màn hình frontend → API](#phụ-lục-c--màn-hình-frontend--api)

---

## 0. Tổng quan & kiến trúc

### 0.1 Hiện trạng

| Thành phần | Trạng thái |
|---|---|
| Database (SQL Server, `BankingSystem`) | **Đã có**: 14 bảng + 18 lookup + 14 view + 63 `dbo.sp_*` + 54 `dbo.fn_*`, deploy bằng `database/deploy.ps1` lên `localhost\SQLEXPRESS01` |
| Backend API | **Chưa có** — sẽ dựng ASP.NET Core (C#) |
| Frontend | **Chưa có** — sẽ dựng React + TypeScript (Vite) |

### 0.2 Quyết định stack (đã chốt)

| Vấn đề | Lựa chọn | Lý do |
|---|---|---|
| Database | **Giữ SQL Server**, không migrate | 63 proc + deploy.ps1 đã chạy được, migrate PostgreSQL là làm lại từ đầu |
| Nơi chứa business logic | **Stored procedures** là nguồn sự thật | Đã cài đặt xong, có chống-đua (guarded UPDATE) |
| API cho React | **ASP.NET Core** (C#, .NET LTS) gọi `sp_*` qua ADO.NET (`Microsoft.Data.SqlClient`) | Không ORM (không EF Core), mapper mỏng, hợp SQL Server. Xem `backend/Plan.md` §0.1 (vì sao không ORM, tham số có tên chứ không vị trí) |
| Frontend | **React + TypeScript** | Cả 2 tài liệu định hướng đều nhắc React |
| ~~C++ core~~ | **Bỏ** (2026-09-09) | Proc đã là nguồn sự thật; core C++ chỉ là bản sao thứ 2 của quy tắc, phải tự đồng bộ tay, thêm 1 toolchain. Business thật chạy 1 backend. Domain OOP + tính toán → tầng service backend (§3.5) |
| ~~Spring Boot (Java)~~ | **Bỏ** (2026-09-12) | Người dùng muốn code backend bằng C#. Đổi sang ASP.NET Core, kiến trúc giữ nguyên (proc là nguồn sự thật, thin service, không ORM) |

### 0.3 Kiến trúc 3 tầng

```
┌────────────────┐   HTTP/JSON    ┌────────────────────┐  ADO.NET {call dbo.sp_*} ┌──────────────────────┐
│  React + TS    │ ─────────────▶ │  ASP.NET Core API  │ ─────────────────────▶ │ SQL Server           │
│  (Vite SPA)    │ ◀───────────── │  (envelope, JWT)   │ ◀───────────────────── │ BankingSystem        │
└────────────────┘  ApiResponse   └────────────────────┘   result set + THROW   │  - 63 sp_*  (ghi)    │
                                   - domain/tính toán (§3.5)                     │  - 14 vw_*  (đọc)    │
                                   - BackgroundService job đáo hạn tiết kiệm     │  - 54 fn_*  (validate)│
                                                                                └──────────────────────┘
```

**Vì sao 1 backend:** mọi thao tác ghi đi qua `sp_*` ⇒ một bản cài đặt quy tắc nghiệp vụ duy nhất. Backend chỉ: validate input (DataAnnotations) → gọi proc → map result (§3.3). Phần C# tự tính (không có trong proc) chỉ còn **lịch trả góp** (§3.5). Job nền (đáo hạn tiết kiệm) là một `BackgroundService` gọi proc — không cần tiến trình riêng.

### 0.4 Bug DB — ✅ đã sửa hết & verify

17 bug (+1) đã vá và verify bằng `deploy.ps1 -Seed` → `DEPLOY OK` + `SEED OK` (2026-09-07, re-check 2026-09-09: cả 17 fix đều có trong file `.sql`). Nhóm nặng nhất: auth-bypass OTP replay, `ABS(CHECKSUM(NEWID()))` tràn INT.MIN, `vw_CardDetails` lộ PAN, view sai tên. Chi tiết nằm trong git history (commit `d9bdc7c`, `7d748e9`).

---

## 1. Hợp đồng chuẩn dùng chung (Shared Contract)

> **Cả FE và BE phải code theo đúng phần này.** Đây là chống-xung-đột số 1.

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
| Backend (C#) | `decimal` + `Math.Round(v, 2, MidpointRounding.AwayFromZero)` khắp nơi. Không cần class `Money` bọc lại — chỉ tính trong 1 currency (lịch trả góp §3.5); chuyển tiền do proc lo |
| Currency | Field **riêng**, mã từ lookup `Currency`: `USD | EUR | GBP | JPY | VND`. **Không có FX / quy đổi.** Mỗi transaction/loan/saving kế thừa currency của banking account nguồn |
| Làm tròn | **half-up** về 2 chữ số (khớp `CAST(... AS DECIMAL(18,2))` của T-SQL) |
| Cộng/trừ khác currency | **Cấm** — proc chặn; backend không bao giờ cộng tiền 2 currency |

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
| Timezone server | `Asia/Ho_Chi_Minh` — .NET không có "timezone mặc định của app" như JVM; đọc `DATETIME` qua ADO.NET giữ `DateTimeKind.Unspecified`, không gọi `.ToLocalTime()/.ToUniversalTime()`. SQL Server dùng giờ máy |
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

Stored proc trả về: **1..N dòng từ một `vw_*`** + cột `message` (hoặc `result_message`) ở cuối. ASP.NET Core chuẩn hoá lại:

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
| Validate input sai (DataAnnotations) | `400` |
| ID không tồn tại (`fn_*_validate_id = 0`) | `404` |
| Vi phạm quy tắc nghiệp vụ (số dư, trạng thái, trùng, sai state machine) | `409` |
| Sai giá trị enum / tham số ngoài miền | `422` |
| Khác | `500` |

- `error.code` = **đúng số `THROW`** của proc.
- `message` giữ nguyên tiếng Anh của proc; FE có thể hiển thị trực tiếp hoặc map theo `error.code`.

### 1.7 Casing & field mapping

- DB dùng `snake_case`; JSON/DTO dùng `camelCase`.
- Một tầng mapper **tường minh** trong backend theo từng view (không auto). Ví dụ `vw_TransactionDetails`:

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
- **Không bao giờ** trả ra client: `password_hash`, `cvv_hash`, `otp_code` (xem 1.10).

### 1.9 Phân trang & tìm kiếm

- Proc `*_search` trả **toàn bộ** dòng, không phân trang.
- Contract: backend nhận query `?page=0&size=20&sort=createdAt,desc`, cắt trang **trong bộ nhớ**, trả:
  - body: `data` = array trang hiện tại
  - header: `X-Total-Count: <tổng>`
- Ngưỡng nâng cấp: khi một search trả > ~5.000 dòng, chuyển sang proc có `@offset/@fetch` (`OFFSET ... FETCH NEXT`). Chưa cần cho đồ án.

### 1.10 Xác thực & OTP

**DB không giữ** session / JWT / hash mật khẩu. ASP.NET Core sở hữu:

| Việc | Cách làm |
|---|---|
| Hash mật khẩu | **`PasswordHasher<T>`** (`Microsoft.AspNetCore.Identity`, PBKDF2 — không cần BCrypt.Net ngoài). Proc lưu nguyên chuỗi truyền vào → **truyền hash** vào `@password` của `sp_account_register` / `sp_account_change_password` / `sp_account_reset_password`. `sp_account_login` so khớp bằng `password_hash = @password` nên **login phải so ở tầng backend**: đọc account, `hasher.VerifyHashedPassword(...)`, rồi (nếu cần) vẫn gọi `sp_account_login` với hash để lấy `vw_Account`. |
| JWT | Phát khi login OK (claims: `sub`=account_id, `role`, `username`) bằng `Microsoft.AspNetCore.Authentication.JwtBearer`. TTL 1h, refresh token 7 ngày (tuỳ chọn). |
| `LoginHistory` | **Backend gọi** `sp_login_history_create` sau mỗi lần login (thành công/thất bại) với `ip_address`, `device` từ request. |
| Khoá đăng nhập | Đếm số lần sai **phía backend** (Redis hoặc bảng phụ) — DB không có cột. Sai ≥ 5 lần / 15 phút → `sp_admin_update_account_status` set `Locked` hoặc chặn tạm ở backend. |
| OTP | `sp_otp_generate_otpcode` **trả `otp_code` plaintext trong result set**. Backend **KHÔNG** forward cho client. Gửi qua email/SMS (dev: ghi log). Response chỉ có `{ "otpId": ..., "expiresAt": ... }`. |

**OTP replay (đã vá — 2026-09-07):** trước đây `sp_otp_generate_otpcode` đánh dấu OTP cũ là `verified = 1`, khiến sinh OTP lần 2 là `sp_account_activate` / `sp_account_reset_password` qua được dù chưa nhập mã. Nay OTP cũ bị cho **hết hạn** (`SET expired_at = GETDATE()`), chỉ `sp_otp_verify` mới set `verified = 1`. Khi làm OTP xác thực chuyển tiền (Phase 6) cần thêm cột `consumed` + `sp_otp_consume` — xem ghi chú trong `sp_otp_generate_otpcode.sql`.

### 1.11 Hợp đồng đồng thời (concurrency)

- Mọi thao tác chạm số dư **bắt buộc** dùng pattern *guarded UPDATE* (một câu lệnh, kiểm tra + trừ/cộng cùng lúc):
  ```sql
  UPDATE BankingAccount
  SET balance = balance - @x, available_balance = available_balance - @x
  WHERE bank_account_id = @id AND status = 'Active' AND available_balance >= @x;
  IF @@ROWCOUNT = 0 THROW <code>, '...', 1;
  ```
- **Cấm** `SELECT balance` rồi `UPDATE` (race condition).
- Backend: **luôn** qua `sp_*`, không tự viết SQL số dư. Job nền cũng gọi proc (§3.5).

### 1.12 Mã lỗi — hai hệ đang tồn tại

T-SQL `THROW` yêu cầu số ≥ 50000. Hiện có 2 hệ:

| Hệ | Module | Bước nhảy |
|---|---|---|
| 6 chữ số | account (11xxxx–15xxxx), bank_transaction (21xxxx–27xxxx), banking_account (31xxxx–34xxxx), beneficiary (41xxxx–44xxxx), saving_account (35xxxx), notification (111xxx–114xxx) | `+10` |
| 6 chữ số, `+1` | login_history (101xxx–102xxx), otp (121xxx–122xxx) | `+1` |
| **5 chữ số** (chưa remap, vẫn ≥ 50000 nên chạy tốt) | branch (51xxx–56xxx), card (61xxx–64xxx), customer (71xxx–76xxx), employee (81xxx–87xxx), loan (91xxx–96xxx) | `+1` |

→ **`SqlErrorCatalog` phía backend xử lý cả hai hệ** (Phụ lục B). Proc **mới** đặt mã theo chuẩn `MMSPCC` 6 chữ số, ≥ 50000 (xem memory *THROW error number range*). Không bắt buộc remap 5 chữ số cũ.

---

## 2. Tầng Database — bổ sung

> Schema + 63 proc đã có và chạy được. 17 bug cũ đã vá (xem §0.4 + git history). Phần dưới chỉ còn **việc chưa làm**: proc bổ sung (§2.1) và deploy script (§2.2).
>
> ⚠️ Stored procedure có **deferred name resolution** → bug tham chiếu sai tên vẫn CREATE được lúc deploy, chỉ nổ khi EXEC. `DEPLOY OK` một mình **không** đủ — phải chạy `-Seed` + integration test.

### 2.1 Procedure bổ sung

| Proc | File | Chữ ký | Mục đích | Mã lỗi | Trạng thái |
|---|---|---|---|---|---|
| `dbo.sp_admin_create_employee_account` | `account/admin_create_employee_account.sql` | `@username, @email, @phone_number, @password` | Admin tạo `Account` role `Employee` status `Active` (thay INSERT thẳng trong seed) | `170000`–`170030` | ✅ đã tạo + test |
| `dbo.sp_admin_update_account_status` | `account/admin_update_account_status.sql` | `@account_id BIGINT, @new_status VARCHAR(20)` | Lock / Disable / Enable account | `171000`–`171020` | ✅ đã tạo + test |
| ~~`dbo.sp_notification_list`~~ | — | — | **Bỏ** — `sp_notification_search(@account_id, NULL, 0, NULL, NULL)` đã làm "unread only", `(@account_id, NULL, NULL, NULL, NULL)` là "tất cả". YAGNI. | — | — |

> Bỏ `sp_loan_get_schedule` + bảng `LoanRepaymentSchedule` — backend tính runtime (§3.5 `AmortizationSchedule`) từ `amount`, `interest_rate`, `duration_months`, `start_date`. YAGNI.
>
> `sp_saving_account_settle_matured` (đáo hạn sổ tiết kiệm) — nếu chưa có proc thì thêm 1 proc tối giản: `UPDATE SavingAccount SET status='Matured' WHERE status='Active' AND maturity_date <= CAST(GETDATE() AS DATE)`. Backend gọi qua `BackgroundService` (§3.5). **Không** có job "vay quá hạn" — `LoanStatus` không có giá trị `Overdue`, YAGNI.

### 2.2 `deploy.ps1` — đã viết lại

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

## 3. Backend — ASP.NET Core

> ⚠️ Đổi từ Spring Boot (Java) sang ASP.NET Core (C#) ngày 2026-09-12 — người dùng muốn code backend bằng C#, kiến trúc không đổi (proc là nguồn sự thật, service mỏng, không ORM). Chi tiết cầm tay chỉ việc (thứ tự viết, checklist, giải thích từng dòng) ở `backend/Plan.md` — phần dưới chỉ là **hợp đồng** giữa các module.

### 3.1 Cấu trúc namespace `Backend`

```
Db/           StoredProcedureExecutor, Rows (helper trim NCHAR + ép DateTime/decimal)
Common/       ApiResponse<T>, ApiError, ApiExceptionHandler (IExceptionHandler), SqlErrorCatalog, PagedResponse
Security/     JwtIssuer, OwnershipGuard, dùng sẵn Microsoft.AspNetCore.Authentication.JwtBearer + Identity.PasswordHasher<T>
Auth/         AuthController, AuthService
Customer/     CustomerController, CustomerService
Employee/     ...
Branch/  BankingAccount/  Card/  Transaction/  Loan/  Saving/  Beneficiary/  Notification/
         LoginHistory/  Admin/
Loan/         + AmortizationSchedule.cs (§3.5 — tính toán duy nhất không có trong proc)
Saving/       + MaturedSavingsJob.cs    (§3.5 — BackgroundService gọi sp_saving_account_settle_matured)
*/Dto/        CreateXxxRequest/UpdateXxxRequest (record + DataAnnotations)   XxxResponse (record mirror view)
```

**Không** có `DbContext` / EF Core / repository interface — chỉ `StoredProcedureExecutor` + mapper.
**Không** có tầng "domain object" song song (Loan/SavingAccount/BankingAccount class với state machine) — proc đã ép mọi state + invariant, class C# lặp lại chỉ tạo gánh nặng đồng bộ. Service = validate → gọi proc → map (§3.3).

### 3.2 Thành phần cốt lõi

**`ApiResponse` / `ApiError`**
```csharp
public record ApiResponse<T>(bool Success, string? Message, T? Data, ApiError? Error)
{
    public static ApiResponse<T> Ok(string? message, T? data) => new(true, message, data, null);
    public static ApiResponse<T> Fail(string? message, ApiError error) => new(false, message, default, error);
}
public record ApiError(int Code, string Domain);
```

**`StoredProcedureExecutor`** — điểm tiếp xúc DUY NHẤT với `sp_*`. Tham số **có tên** (ADO.NET bind theo tên, khác JDBC positional):
```csharp
public sealed class StoredProcedureExecutor(IConfiguration config)
{
    private readonly string _connectionString = config.GetConnectionString("BankingSystem")!;

    public async Task<List<Dictionary<string, object?>>> CallAsync(string proc, params (string Name, object? Value)[] args)
    {
        await using var conn = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand($"dbo.{proc}", conn) { CommandType = CommandType.StoredProcedure };
        foreach (var (name, value) in args) cmd.Parameters.AddWithValue(name, value ?? DBNull.Value);
        await conn.OpenAsync();
        await using var reader = await cmd.ExecuteReaderAsync();
        return await Rows.ToMapsAsync(reader);
    }

    public string? Message(Dictionary<string, object?> row)
        => (row.GetValueOrDefault("message") ?? row.GetValueOrDefault("result_message"))?.ToString();
}
```

**`SqlErrorCatalog`** — map mã `THROW` → (domain, HTTP). Dùng list khoảng vì hai hệ mã interleave (account 12xxxx vs otp 121xxx).
```csharp
public static class SqlErrorCatalog
{
    public record Entry(string Domain, int Status);
    private record Band(int Lo, int Hi, string Domain, int Status);

    // Sắp theo Lo; first-match. Đầy đủ dải ở Phụ lục B.
    private static readonly List<Band> Bands =
    [
        new( 51000,  56999, "branch",           StatusCodes.Status409Conflict),
        new( 61000,  64999, "card",             StatusCodes.Status409Conflict),
        new( 71000,  76999, "customer",         StatusCodes.Status409Conflict),
        new( 81000,  87999, "employee",         StatusCodes.Status409Conflict),
        new( 91000,  96999, "loan",             StatusCodes.Status409Conflict),
        new(101000, 102999, "login_history",    StatusCodes.Status400BadRequest),
        new(110000, 110999, "account",          StatusCodes.Status409Conflict),
        new(111000, 114999, "notification",     StatusCodes.Status409Conflict),
        new(120000, 120999, "account",          StatusCodes.Status409Conflict),
        new(121000, 122999, "otp",              StatusCodes.Status422UnprocessableEntity),
        new(130000, 159999, "account",          StatusCodes.Status409Conflict),
        new(160000, 179999, "admin",            StatusCodes.Status409Conflict),
        new(210000, 279999, "bank_transaction", StatusCodes.Status409Conflict),
        new(310000, 349999, "banking_account",  StatusCodes.Status409Conflict),
        new(350000, 359999, "saving_account",   StatusCodes.Status409Conflict),
        new(410000, 449999, "beneficiary",      StatusCodes.Status409Conflict),
    ];

    public static Entry Lookup(int code)
    {
        if (code < 50000) return new Entry("system", StatusCodes.Status500InternalServerError);
        var b = Bands.FirstOrDefault(b => code >= b.Lo && code <= b.Hi);
        return b is null ? new Entry("business", StatusCodes.Status422UnprocessableEntity) : new Entry(b.Domain, b.Status);
    }
    // "id không tồn tại" (mã kết thúc ...000 và message chứa "does not exist"/"Invalid") → override 404 ở handler
}
```

**`ApiExceptionHandler`** (dùng `IExceptionHandler`, có sẵn từ .NET 8 — thay cho middleware tự viết tay):
```csharp
public sealed class ApiExceptionHandler : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext ctx, Exception ex, CancellationToken ct)
    {
        if (ex is not SqlException sql) return false;
        var e = SqlErrorCatalog.Lookup(sql.Number);
        var msg = sql.Message.Split('\n')[0];
        var status = msg.Contains("does not exist", StringComparison.OrdinalIgnoreCase)
                     || msg.Contains("Invalid", StringComparison.OrdinalIgnoreCase)
            ? StatusCodes.Status404NotFound : e.Status;
        ctx.Response.StatusCode = status;
        await ctx.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(msg, new ApiError(sql.Number, e.Domain)), ct);
        return true;
    }
}
```
Lỗi validate (`[Required]`… fail) được `ApiBehaviorOptions.InvalidModelStateResponseFactory` xử lý riêng trong `Program.cs`, không đi qua đây — xem `backend/Plan.md` §5.1/§5.3.

**JSON: tiền là string, ngày không offset.** `PropertyNamingPolicy = JsonNamingPolicy.CamelCase` + 2 converter nhỏ (`DecimalAsStringConverter`, `DateTimeNoOffsetConverter`) đăng ký trong `Program.cs` — không cần class config riêng như Jackson. Chi tiết `backend/Plan.md` §5.4.

### 3.3 Hai ví dụ đầy đủ (mẫu để nhân bản)

**Branch — create** (`sp_branch_create` → `POST /api/branches`)
```csharp
[ApiController, Route("api/branches")]
public sealed class BranchController(BranchService service) : ControllerBase
{
    [HttpPost, Authorize(Roles = "Admin")]
    public Task<ApiResponse<BranchResponse>> Create([FromBody] CreateBranchRequest req) => service.CreateAsync(req);
}

public record CreateBranchRequest(
    [property: Required, MaxLength(100)] string BranchName,
    [property: Required, MaxLength(100)] string Address,
    [property: Required, MaxLength(20)]  string PhoneNumber);

public record BranchResponse(string BranchId, string BranchName, string Address, string PhoneNumber,
                              string Status, DateTime? CreatedAt, DateTime? UpdatedAt);

public sealed class BranchService(StoredProcedureExecutor sp)
{
    public async Task<ApiResponse<BranchResponse>> CreateAsync(CreateBranchRequest r)
    {
        var rows = await sp.CallAsync("sp_branch_create",
            ("@branch_name", r.BranchName), ("@address", r.Address), ("@phone_number", r.PhoneNumber));
        var row = rows[0];
        return ApiResponse<BranchResponse>.Ok(sp.Message(row), Map(row));
    }
    private static BranchResponse Map(Dictionary<string, object?> m) => new(
        Rows.Str(m, "branch_id")!, Rows.Str(m, "branch_name")!, Rows.Str(m, "address")!,
        Rows.Str(m, "phone_number")!, Rows.Str(m, "status")!, Rows.Dt(m, "created_at"), Rows.Dt(m, "updated_at"));
}
```

**Transaction — transfer** (`sp_bank_transaction_transfer` → `POST /api/transactions/transfer`)
```csharp
[HttpPost("transfer"), Authorize(Roles = "Customer")]
public async Task<ApiResponse<TransactionResponse>> Transfer([FromBody] TransferRequest req)
{
    await ownership.AssertOwnsBankAccountAsync(User, req.FromBankAccountId);   // TK nguồn phải của người đăng nhập
    var rows = await sp.CallAsync("sp_bank_transaction_transfer",
        ("@from_account_id", req.FromBankAccountId), ("@to_account_id", req.ToBankAccountId),
        ("@amount", req.Amount), ("@fee", req.Fee ?? 0m), ("@description", req.Description));
    var row = rows[0];
    await notifier.AfterTransferAsync(row);                                   // §Phase 10: bắn Notification
    return ApiResponse<TransactionResponse>.Ok(sp.Message(row), TransactionResponse.From(row));
}

public record TransferRequest(
    [property: Required] long FromBankAccountId,
    [property: Required] long ToBankAccountId,
    [property: Required, Range(0.01, double.MaxValue)] decimal Amount,
    [property: Range(0, double.MaxValue)] decimal? Fee,
    [property: MaxLength(255)] string? Description);
```

### 3.4 Quy tắc chung backend

- Mọi controller trả `ApiResponse<T>`.
- Validate input bằng DataAnnotations **trước** khi gọi proc (fail-fast, HTTP 400 — tự động qua `[ApiController]`).
- **Không** `TransactionScope` — proc tự `BEGIN/COMMIT/ROLLBACK`. Một request = một `sp.CallAsync`.
- Role check: `[Authorize(Roles = "Customer"|"Employee"|"Admin")]`; nghiệp vụ Loan review thêm check `position = 'Loan Officer'`.
- Ownership: `OwnershipGuard` — customer chỉ thao tác trên banking account / loan / saving / beneficiary của chính mình (query nhẹ qua `fn_*_validate_owner` hoặc view).
- Danh sách endpoint đầy đủ: **Phụ lục A**.

### 3.5 Domain / tính toán + job nền

> Đây là **toàn bộ** phần C# "tự làm logic". Mọi thứ khác đi qua proc. Nếu chỗ này thấy trống thì đúng — kiến trúc "proc là nguồn sự thật" khiến tầng app mỏng theo thiết kế.

**`Loan/AmortizationSchedule.cs`** — lịch trả góp cho `GET /loans/{id}/schedule`. Khớp công thức `sp_loan_apply` (§1.3): `r = annual/12/100` ; `M = P·r·(1+r)^n / ((1+r)^n − 1)` ; `r == 0` → `M = P/n`. Kỳ cuối nuốt phần lẻ để dư nợ về 0.

```csharp
public record AmortRow(int Period, decimal Payment, decimal Principal, decimal Interest, decimal Balance);

public static class AmortizationSchedule
{
    public static decimal MonthlyPayment(decimal principal, decimal annualPct, int months)
    {
        if (months <= 0) throw new ArgumentException("Duration must be greater than zero.");
        double r = (double)annualPct / 12.0 / 100.0;
        if (r == 0.0) return Math.Round(principal / months, 2, MidpointRounding.AwayFromZero);
        double p = (double)principal, pw = Math.Pow(1.0 + r, months);
        return Math.Round((decimal)(p * r * pw / (pw - 1.0)), 2, MidpointRounding.AwayFromZero);
    }

    public static List<AmortRow> Build(decimal principal, decimal annualPct, int months)
    {
        var pay = MonthlyPayment(principal, annualPct, months);
        double r = (double)annualPct / 12.0 / 100.0;
        var bal = Math.Round(principal, 2, MidpointRounding.AwayFromZero);
        var rows = new List<AmortRow>(months);
        for (int k = 1; k <= months; k++)
        {
            var interest = Math.Round(bal * (decimal)r, 2, MidpointRounding.AwayFromZero);
            var principalPart = pay - interest;
            var thisPay = pay;
            if (k == months) { principalPart = bal; thisPay = principalPart + interest; }
            bal -= principalPart;
            rows.Add(new AmortRow(k, thisPay, principalPart, interest, bal));
        }
        return rows;
    }
}
```

Test (`AmortizationScheduleTests`): `Build(12_000_000, 12.00m, 12)` → 12 dòng; `Σ Principal == principal`; dòng cuối `Balance == 0`.

**`Saving/MaturedSavingsJob.cs`** — thay batch job riêng bằng một `BackgroundService` (có sẵn trong `Microsoft.Extensions.Hosting`, không cần Quartz.NET):

```csharp
public sealed class MaturedSavingsJob(IServiceScopeFactory scopeFactory, ILogger<MaturedSavingsJob> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1));
        while (await timer.WaitForNextTickAsync(ct))
        {
            var vn = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
            var now = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, vn);
            if (now.Hour != 0 || now.Minute != 5) continue;   // chạy 1 lần lúc 00:05

            using var scope = scopeFactory.CreateScope();
            var sp = scope.ServiceProvider.GetRequiredService<StoredProcedureExecutor>();
            var rows = await sp.CallAsync("sp_saving_account_settle_matured");
            log.LogInformation("Settled {Count} matured saving account(s)", rows.Count);
        }
    }
}
```

Đăng ký bằng `builder.Services.AddHostedService<MaturedSavingsJob>()` trong `Program.cs`. Không cần thư viện ngoài, không tiến trình riêng.

**Bỏ qua có chủ đích:**
- Class `Money` bọc `decimal` — `Math.Round(v, 2, AwayFromZero)` + converter §3.2 đã đủ; chỉ thêm khi phải cộng tiền nhiều currency (hiện không).
- `Luhn` trong C# — `sp_card_create` sinh + check digit trong SQL; FE muốn validate số thẻ gõ tay thì tự làm ở `validation.ts`.
- Domain state machine (Loan/Saving) trong C# — proc đã ép; xem §3.1.

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

- `types/models.ts` viết **thủ công theo §1** (hoặc sinh từ OpenAPI của backend — Swashbuckle — bằng `openapi-typescript`).
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

## 5. Thứ tự thực hiện (Roadmap)

| Phase | Nội dung | Xong khi |
|---|---|---|
| **0** | ✅ Xong: schema + 63 proc + 17 bug DB đã vá + `deploy.ps1` (`DEPLOY OK` + `SEED OK`). Còn lại: proc bổ sung §2.1 (`sp_admin_*`, và `sp_saving_account_settle_matured` nếu chưa có) — làm ở Phase 3/8/10 | — |
| **1** | Chốt §1 (contract) với cả nhóm. Tạo repo `backend/`, `frontend/` | Contract được review, 2 skeleton build rỗng chạy được |
| **2** | ASP.NET Core skeleton: `StoredProcedureExecutor`, `ApiResponse`, `ApiExceptionHandler`, `SqlErrorCatalog`, JSON converters; 1 lát cắt dọc `sp_branch_create` → `POST /api/branches` + integration test | 1 endpoint end-to-end xanh |
| **3** | Auth: register → OTP → activate → login (JWT) → `/me`; `PasswordHasher<T>`; backend ghi `LoginHistory`. FE: trang Login/Register/OtpVerify + `AuthContext` + `ProtectedRoute` | Đăng ký + đăng nhập thật, token hoạt động |
| **4** | Customer / Employee / Branch CRUD: backend endpoints + React pages | 3 module CRUD đủ trên cả 2 tầng |
| **5** | BankingAccount + Card: mở/đóng/freeze TK, phát hành/khoá thẻ. FE: OpenAccount, Cards, IssueCard | Mở TK + phát thẻ (số thẻ pass Luhn — do proc sinh) |
| **6** | **Transactions** (trọng yếu về đồng thời): deposit/withdraw/transfer/payment. FE: Transfer + TransactionHistory | Test 20 lệnh chuyển song song vượt số dư → đúng phần được phép thành công, `available_balance ≥ 0` |
| **7** | Loan: apply/review/disburse/repay. Backend `AmortizationSchedule` + test (§3.5). FE: LoanApply, LoanDetail (bảng trả góp), Employee `LoanReviewQueue` | Vòng đời khoản vay đủ; lịch trả góp FE = C# = công thức proc |
| **8** | Saving: open/close/settle-matured. Backend `MaturedSavingsJob` (`BackgroundService`, §3.5). FE: Savings, OpenSaving | Mở + tất toán (đúng hạn & trước hạn); job đổi status `Matured` |
| **9** | Beneficiary + Notification. Backend bắn `sp_notification_create` sau khi transfer/loan thành công (best-effort, không rollback nghiệp vụ nếu notify lỗi) | Chuyển tiền xong nhận thông báo |
| **10** | Admin + Dashboard: `sp_admin_update_account_status`, `vw_CustomerStatistics` (đã sửa), trang Stats | Admin khoá/mở account; dashboard hiện số liệu |
| **11** | Hardening: gửi OTP qua email thật, rate-limit + khoá đăng nhập, `/security-review`, load test transfer, CI (`deploy.ps1` + `mvn test` + `npm run build && npm test`) | CI xanh toàn bộ |

---

## 6. Kiểm thử (Verification)

**Database** — ✅ đã chạy 2026-09-07
```bash
pwsh -File database/deploy.ps1 -Seed
# DEPLOY OK + SEED OK; 1 branch, 2 customer, 2 employee, 2 bank account, 1 card, 1 loan Disbursed, 1 saving, 1 notification
```
Smoke test 30 case (search/get toàn bộ module + 2 proc admin mới): **30/30 PASS**, mã lỗi 170000/171010 đúng band.

**Backend (ASP.NET Core)**
```bash
cd backend && dotnet test
# integration test trỏ DB test (dựng bằng chính deploy.ps1 trước khi chạy, hoặc Testcontainers for .NET mssql)
```
Kịch bản tối thiểu: `POST /api/branches` (201 + envelope) · register→otp→activate→login (JWT hợp lệ) · transfer thiếu số dư → 409 + `error.code = 250040` · `AmortizationScheduleTests` (§3.5): Σ Principal == principal, dư nợ kỳ cuối == 0.

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
| POST | `/login` | `sp_account_login` (+ PasswordHasher + JWT + `sp_login_history_create`) | - | `{username,password}` | `{token,account:AccountView}` |
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

> Dùng để nạp `SqlErrorCatalog`. Mã đầu dải thường = "id không tồn tại" → map HTTP **404**; mã cuối dải = "UPDATE/INSERT ảnh hưởng 0 dòng" (vi phạm quy tắc) → **409**.

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

- C++ core đã bỏ (2026-09-09); Spring Boot/Java đã đổi sang ASP.NET Core/C# (2026-09-12) — xem §0.2. Domain OOP + tính toán ở tầng service backend (§3.5); job nền là `BackgroundService`.
- SQL sửa DB (§2) là **snippet để chép tay** vào file `.sql` tương ứng, không ghi đè tự động.
- Không viết sẵn cả 60 controller — dùng 2 mẫu §3.3 nhân bản theo Phụ lục A.
- Mọi thay đổi phải giữ `database/deploy.ps1` chạy ra `DEPLOY OK` (xem memory *Clean deploy workflow*).
- CI (§5 Phase 11): `mvn test` cũ đổi thành `dotnet test`.
