# API Contract — Hợp đồng giao tiếp

> **Loại tài liệu:** API Contract / Interface Specification.
> **Dùng để:** backend và frontend thống nhất định dạng dữ liệu, endpoint và mã lỗi. Code phải theo đúng file này; muốn đổi thì sửa file này trước.
> **Nguồn sự thật cho tên tham số / cột:** file `.sql` trong `database/src/`. Nếu bảng dưới khác file `.sql`, tin file `.sql` và sửa lại bảng.

## Mục lục

- [1. Hợp đồng chung](#1-hợp-đồng-chung)
- [2. Dải mã lỗi → HTTP status](#2-dải-mã-lỗi--http-status)
- [3. Danh sách endpoint](#3-danh-sách-endpoint)
- [4. Mã lỗi theo procedure](#4-mã-lỗi-theo-procedure)
- [5. Màn hình frontend → API](#5-màn-hình-frontend--api)

---

## 1. Hợp đồng chung

> **Cả FE và BE phải code theo đúng phần này.** Đây là chống-xung-đột số 1.

### 1.1 Định danh (ID)

| Nhóm | Kiểu DB | Định dạng | JSON | Ghi chú |
|---|---|---|---|---|
| `Customer` / `Employee` / `Branch` | `NCHAR(10)` (pad khoảng trắng) | `CIF` + 7 số / `EMP` + 7 số / `BR` + 8 số | **string đã `.trim()`** | vd `"CIF0000001"`. Mọi tầng phải trim khi đọc, pad-phải-tới-10 khi so sánh/ghi |
| `Account`, `BankingAccount`, `Card`, `BankTransaction`, `Loan`, `SavingAccount`, `Beneficiary`, `Notification`, `OTP`, `LoginHistory` | `BIGINT IDENTITY` | số nguyên | **number** | Quy mô đồ án < 2^53 nên an toàn. Nếu lo xa: serialize string |
| `bank_account_number` | `NCHAR(20)` | 20 chữ số | **string** | Không bao giờ dùng number (leading zero) |
| `card_number` | `VARCHAR(20)` | 16 chữ số + Luhn | **string** | idem |

### 1.2 Tiền tệ

| Khía cạnh | Quy ước |
|---|---|
| Kiểu DB | `DECIMAL(18, 2)` cho **tất cả** cột tiền |
| JSON | **string** `"1000000.00"` — luôn đúng 2 chữ số lẻ. **Không** dùng `number` (mất chính xác float) |
| Backend (C#) | `decimal` + `Math.Round(v, 2, MidpointRounding.AwayFromZero)` khắp nơi. Không cần class `Money` bọc lại — chỉ tính trong 1 currency (lịch trả góp); chuyển tiền do proc lo |
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

**Map HTTP status** (nguồn: `SqlErrorCatalog`, §2 + §4):

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
- Backend: **luôn** qua `sp_*`, không tự viết SQL số dư. Job nền cũng gọi proc.

### 1.12 Mã lỗi — hai hệ đang tồn tại

T-SQL `THROW` yêu cầu số ≥ 50000. Hiện có 2 hệ:

| Hệ | Module | Bước nhảy |
|---|---|---|
| 6 chữ số | account (11xxxx–15xxxx), bank_transaction (21xxxx–27xxxx), banking_account (31xxxx–34xxxx), beneficiary (41xxxx–44xxxx), saving_account (35xxxx), notification (111xxx–114xxx) | `+10` |
| 6 chữ số, `+1` | login_history (101xxx–102xxx), otp (121xxx–122xxx) | `+1` |
| **5 chữ số** (chưa remap, vẫn ≥ 50000 nên chạy tốt) | branch (51xxx–56xxx), card (61xxx–64xxx), customer (71xxx–76xxx), employee (81xxx–87xxx), loan (91xxx–96xxx) | `+1` |

→ **`SqlErrorCatalog` phía backend xử lý cả hai hệ** (§2). Proc **mới** đặt mã theo chuẩn `MMSPCC` 6 chữ số, ≥ 50000 (xem `AGENTS.md`). Không bắt buộc remap 5 chữ số cũ.

---

## 2. Dải mã lỗi → HTTP status

Backend tra số `THROW` của proc trong bảng này (khớp dải đầu tiên). Nếu message chứa "does not exist" hoặc "Invalid" thì trả **404**, bất kể dải nào. Mã < 50000 là lỗi hệ thống (**500**). Mã ≥ 50000 nhưng không thuộc dải nào: **422**.

| Từ | Đến | Domain | HTTP |
|---|---|---|---|
| 51000 | 56999 | branch | 409 |
| 61000 | 64999 | card | 409 |
| 71000 | 76999 | customer | 409 |
| 81000 | 87999 | employee | 409 |
| 91000 | 96999 | loan | 409 |
| 101000 | 102999 | login_history | 400 |
| 110000 | 110999 | account | 409 |
| 111000 | 114999 | notification | 409 |
| 120000 | 120999 | account | 409 |
| 121000 | 122999 | otp | 422 |
| 130000 | 159999 | account | 409 |
| 160000 | 179999 | admin | 409 |
| 210000 | 279999 | bank_transaction | 409 |
| 310000 | 349999 | banking_account | 409 |
| 350000 | 359999 | saving_account | 409 |
| 410000 | 449999 | beneficiary | 409 |

---

## 3. Danh sách endpoint

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
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_create_customer_profile` | C | Sau khi kích hoạt tài khoản, tạo một lần |
| GET | `/me` | `sp_customer_get_profile` | C | |
| PUT | `/me` | `sp_customer_update_profile` | C | |
| GET | `/{customerId}/summary` | `sp_customer_get_summary` | E, A | |
| GET | `?citizenId=&fullName=` | `sp_customer_search` | E, A | |
| GET | `/statistics` | `vw_CustomerStatistics` | A | |
| PUT | `/{customerId}/branch` | `sp_customer_assign_branch` | E, A | |

### Employee (`/api/employees`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_employee_create_profile` | A | Sau `POST /api/admin/employee-accounts` |
| GET | `/me` | `sp_employee_get_profile` | E | |
| PUT | `/me` | `sp_employee_update_profile` | E | |
| PUT | `/{id}/position` | `sp_employee_update_position` | A | |
| PUT | `/{id}/status` | `sp_employee_update_status` | A | |
| PUT | `/{id}/branch` | `sp_employee_assign_branch` | A | |
| GET | `?citizenId=&fullName=` | `sp_employee_search` | A | |

### Branch (`/api/branches`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_branch_create` | A | |
| PUT | `/{id}` | `sp_branch_update` | A | |
| PUT | `/{id}/status` | `sp_branch_update_status` | A | |
| GET | `/{id}` | `sp_branch_get_info` | - | Công khai (UC-07, PLAN Task 2) |
| GET | `/{id}/summary` | `sp_branch_get_summary` | E, A | |
| GET | `?name=&status=` | `sp_branch_search` | - | Công khai (UC-07, PLAN Task 2) |

### Banking Account (`/api/banking-accounts`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_bank_account_create` | C | |
| GET | `/{id}` | `sp_bank_account_get_details` | C (chủ sở hữu), E | |
| GET | `?number=&customerId=&type=&status=` | `sp_bank_account_search` | E, A, C | C chỉ thấy tài khoản của mình |
| PUT | `/{id}/status` | `sp_bank_account_update_status` | E, A | |

### Card (`/api/cards`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_card_create` | C (chủ tài khoản) | **Response duy nhất** hiện `cardNumber` đầy đủ |
| GET | `/{cardNumber}` | `sp_card_get_details` | C (chủ sở hữu), E | Số thẻ đã che |
| GET | `?bankAccountId=&type=&status=` | `sp_card_search` | C (chủ sở hữu), E | Số thẻ đã che |
| PUT | `/{cardId}/status` | `sp_card_update_status` | C (chủ sở hữu), E | |

### Transaction (`/api/transactions`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/deposit` | `sp_bank_transaction_deposit` | E (Teller) | Bản demo có thể cho C tự nạp |
| POST | `/withdraw` | `sp_bank_transaction_withdraw` | C (chủ sở hữu) | |
| POST | `/transfer` | `sp_bank_transaction_transfer` | C (chủ tài khoản nguồn) | |
| POST | `/payment` | `sp_bank_transaction_payment` | C (chủ tài khoản nguồn) | |
| GET | `/{id}` | `sp_bank_transaction_get_details` | C (bên liên quan), E | |
| GET | `?bankAccountId=&type=&status=&fromDate=&toDate=` | `sp_bank_transaction_search` | C (chủ sở hữu), E | Phân trang |
| PUT | `/{id}/status` | `sp_bank_transaction_update_status` | E, A | |

### Loan (`/api/loans`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_loan_apply` | C | |
| PUT | `/{id}/review` | `sp_loan_review` | LO | Duyệt / từ chối |
| POST | `/{id}/disburse` | `sp_loan_disburse` | LO, E | |
| POST | `/{id}/repay` | `sp_loan_repay` | C (chủ sở hữu) | |
| GET | `/{id}` | `sp_loan_get_details` | C (chủ sở hữu), E | |
| GET | `?customerId=&type=&status=&approvedBy=&fromDate=&toDate=` | `sp_loan_search` | E, LO, C | C chỉ thấy khoản vay của mình |
| GET | `/{id}/schedule` | — | C (chủ sở hữu), E | Tính lúc gọi từ `vw_LoanDetails` |

### Saving (`/api/savings`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_saving_account_open` | C | |
| POST | `/{id}/close` | `sp_saving_account_close` | C (chủ sở hữu) | |
| GET | `/{id}` | `sp_saving_account_get_details` | C (chủ sở hữu), E | |
| GET | `?customerId=&status=&fromDate=&toDate=` | `sp_saving_account_search` | E, C | C chỉ thấy sổ của mình |
| POST | `/settle-matured` | `sp_saving_account_settle_matured` | A | Job nền cũng gọi proc này |

### Beneficiary (`/api/beneficiaries`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/` | `sp_beneficiary_create` | C | |
| PUT | `/{id}` | `sp_beneficiary_update` | C (chủ sở hữu) | |
| GET | `/{id}` | `sp_beneficiary_get_details` | C (chủ sở hữu) | |
| GET | `?name=` | `sp_beneficiary_search` | C | |

### Notification (`/api/notifications`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| GET | `?onlyUnread=` | `sp_notification_search` | C, E (chủ sở hữu) | |
| GET | `/{id}` | `sp_notification_get_details` | Chủ sở hữu | |
| PUT | `/{id}/read` | `sp_notification_mark_is_read` | Chủ sở hữu | |
| — | *(nội bộ)* | `sp_notification_create` | — | Service khác gọi, không mở endpoint |

### Login History (`/api/login-history`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| GET | `?loginStatus=&ip=&device=&fromDate=&toDate=` | `sp_login_history_search` | C, A | C chỉ thấy lịch sử của mình |

### Admin (`/api/admin`)
| Method | Path | Proc | Role | Ghi chú |
|---|---|---|---|---|
| POST | `/employee-accounts` | `sp_admin_create_employee_account` | A | |
| PUT | `/accounts/{id}/status` | `sp_admin_update_account_status` | A | Khoá / mở khoá / vô hiệu hoá |

---

## 4. Mã lỗi theo procedure

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

## 5. Màn hình frontend → API

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
