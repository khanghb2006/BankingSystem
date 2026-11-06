# Banking System — Implementation Plan

> **Dành cho người thực hiện (người hoặc AI agent):** đọc [`AGENTS.md`](AGENTS.md) trước. Làm task theo đúng thứ tự, đánh dấu `- [x]` khi xong. Mỗi task kết thúc bằng một kết quả nghiệp vụ kiểm chứng được bằng test.

**Goal:** Xây API ngân hàng số cho khách hàng, nhân viên và quản trị viên, chạy trên cơ sở dữ liệu SQL Server có sẵn (63 stored procedure).

**Architecture:** Một ASP.NET Core Web API chia theo feature. Mỗi feature đi qua Controller → Service (có interface) → Repository → `Data/` → stored procedure. Quy tắc nghiệp vụ nằm trong proc; API lo HTTP, xác thực, phân quyền, quyền sở hữu, thông báo, job định kỳ và lịch trả góp.

**Tech Stack:** .NET 10, ASP.NET Core Web API (controllers), ADO.NET (`Microsoft.Data.SqlClient`), SQL Server, JWT Bearer, xUnit + `Microsoft.AspNetCore.Mvc.Testing`, Docker Compose.

**Spec:** [`docs/SRS/01_SRS.md`](docs/SRS/01_SRS.md) (yêu cầu, use case) · [`docs/system_design.md`](docs/system_design.md) (kiến trúc) · [`docs/api_contract.md`](docs/api_contract.md) (định dạng, endpoint, mã lỗi) · [`docs/pipeline.md`](docs/pipeline.md) (luồng, Definition of Done).

## Global Constraints

- Mọi thao tác ghi đi qua `dbo.sp_*`. Không EF Core, không Migrations, không viết SQL thay đổi số dư trong C#.
- Chỉ thư mục `Data/` được dùng `Microsoft.Data.SqlClient`.
- Mỗi feature gồm `XController`, `IXService`, `XService`, `XRepository`, `Dtos/`. Feature này cần feature khác thì gọi qua `IXService`.
- Mọi response dùng envelope `{ success, message, data, error: { code, domain } }` (api_contract §1.6).
- Tiền là `decimal` trong C#, chuỗi 2 chữ số lẻ trong JSON (`"1000000.00"`); ngày giờ không offset (`"2026-11-02T14:30:00"`); enum đúng chuỗi gốc (api_contract §1.2–§1.5).
- Không bao giờ trả `password_hash`, `cvv_hash`, `otp_code`. Số thẻ đầy đủ chỉ xuất hiện trong response phát hành thẻ.
- Mật khẩu hash bằng `PasswordHasher` (PBKDF2). JWT thời hạn 60 phút.
- Proc mới: viết `dbo.sp_xxx`, mã `THROW` 6 chữ số ≥ 50000.
- Test chạy trên DB vừa dựng lại bằng `pwsh -File database/deploy.ps1 -Seed`.

## Review Focus

Năm tình huống dễ gây hại nhất mà người dùng thật sẽ gặp. Mỗi tình huống đã có test ở task sở hữu nó.

1. **Nhiều lệnh trừ tiền cùng lúc từ một tài khoản** → số dư khả dụng không bao giờ âm, đúng số lệnh hợp lệ thành công. *(Task 10, Task 11)*
2. **Khách hàng đổi id trong URL/body sang tài nguyên của người khác** → `403` ở mọi endpoint có id. *(Task 6, 9, 10, 11, 13, 14, 16)*
3. **Số tiền nhập sai** (`0`, âm, hơn 2 chữ số lẻ như `100.005`) → `400` trước khi chạm DB; tiền trả ra luôn là chuỗi 2 chữ số lẻ. *(Task 2, Task 10)*
4. **Tài khoản bị Admin khoá khi token còn hạn** → request kế tiếp bị `401`. *(Task 19)*
5. **Rò rỉ dữ liệu nhạy cảm**: mã OTP, hash mật khẩu, số thẻ đầy đủ không xuất hiện trong response hay log production. *(Task 3, 4, 13)*

---

## Lộ trình

| Milestone | Kết quả nghiệp vụ | Task |
|---|---|---|
| **M0 — Nền móng** | Có khung chạy được; khách vãng lai xem được danh sách chi nhánh | 1–2 |
| **M1 — Onboarding** | Người dùng đăng ký, đăng nhập, quản lý hồ sơ; Admin quản lý nhân viên và chi nhánh | 3–8 |
| **M2 — Core Banking (MVP)** | Khách hàng mở tài khoản, nạp/rút, chuyển khoản an toàn | 9–12 |
| **M3 — Sản phẩm** | Thẻ, khoản vay, tiết kiệm | 13–17 |
| **M4 — Vận hành** | Thông báo, khoá tài khoản, lịch sử đăng nhập, thống kê | 18–20 |
| **M5 — Sẵn sàng triển khai** | Bảo mật nâng cao, Docker, CI | 21–22 |
| **M6 — Mở rộng quy mô** | Nhiều bản API chạy sau load balancer; thông báo đi qua message queue | 23–24 |
| **M7 — Middleware pipeline** | Đủ 6 middleware: truy vết, log, header bảo mật, CORS, JWT, giới hạn tốc độ | 25–28 (+ Task 4, 21) |

**Vòng làm chuẩn cho mỗi task** (chi tiết: [`docs/pipeline.md`](docs/pipeline.md) §3): cài đặt Repository → Service → Controller → viết test theo tiêu chí nghiệm thu → `deploy.ps1 -Seed` + `dotnet test` xanh → kiểm Definition of Done → commit.

---

## M0 — Nền móng

### Task 1: Khung solution

**Kết quả:** Solution build và chạy được theo đúng cấu trúc thư mục trong system_design §4.

**Phạm vi:** `BankingSystem.sln`, `BankingSystem.Api/`, `BankingSystem.Tests/`, Swagger.

**Interfaces:**
- Produces: `public partial class Program` để `WebApplicationFactory<Program>` dùng được trong test.

**Tiêu chí nghiệm thu:**
- `dotnet build` và `dotnet test` chạy thành công từ thư mục gốc.
- Ứng dụng khởi động, `GET /swagger/index.html` → `200`.
- Không còn code mẫu của template (`WeatherForecast`).

- [ ] Tạo solution + project Web API (controllers) + project xUnit trong đúng thư mục đã có; tham chiếu Tests → Api.
- [ ] Viết smoke test: khởi động app trong test, `GET /swagger/index.html` trả `200` → chạy thấy fail.
- [ ] Bật Swagger, xoá code mẫu → smoke test xanh.
- [ ] Commit: `chore: scaffold solution, api and test projects`

### Task 2: Lõi nền tảng + xem danh sách chi nhánh

**Kết quả:** Khách vãng lai xem được danh sách và chi tiết chi nhánh (một phần UC-07). Đây là lát cắt đầu tiên đi xuyên mọi tầng, làm khuôn mẫu cho các feature sau.

**Phạm vi:** `Data/` (gọi proc), `Common/` (envelope, xử lý lỗi toàn cục, bảng mã lỗi api_contract §2, JSON converter tiền/ngày, phân trang), `Domain/Branch`, `Features/Branches/` (đọc).

**Dữ liệu:** `sp_branch_search`, `sp_branch_get_info`.

**Interfaces:**
- Produces: khả năng "gọi proc theo tên với tham số có tên → danh sách dòng" trong `Data/`; `ApiResponse<T>`; bảng tra mã lỗi → (domain, HTTP); kết quả phân trang (header `X-Total-Count`). Mọi task sau dùng lại các khối này.

**Tiêu chí nghiệm thu:**
- `GET /api/branches` → `200`, `success: true`, `data` là mảng, id đã cắt khoảng trắng (`"BR00000001"`), có header `X-Total-Count`.
- `GET /api/branches/{id}` với id có thật → `200`, `data` là object.
- `GET /api/branches/{id}` với id không tồn tại → `404`, `success: false`, `error.code` = số `THROW` của proc, `error.domain = "branch"`.
- Unit test JSON: `1000.5m` → `"1000.50"`; `DateTime` → chuỗi không offset. *(Review Focus 3)*
- Tắt SQL Server rồi gọi API → `500` kèm envelope (kiểm tay).
- Ngoài `Data/`, không file nào dùng `Microsoft.Data.SqlClient`.

- [ ] Viết integration test cho 3 tiêu chí HTTP + unit test JSON → chạy thấy fail.
- [ ] Dựng `Data/`, `Common/`, cấu hình connection string (dev, không commit secret).
- [ ] Dựng `Features/Branches` (đọc) → test xanh; kiểm tay tiêu chí `500`.
- [ ] Commit: `feat(branches): public branch list with platform core`

---

## M1 — Onboarding

### Task 3: Đăng ký & kích hoạt tài khoản (UC-01)

**Kết quả:** Khách vãng lai tự tạo tài khoản và kích hoạt bằng OTP.

**Phạm vi:** `Features/Auth`. **Dữ liệu:** `sp_account_register`, `sp_otp_generate_otpcode`, `sp_otp_verify`, `sp_account_activate`.

**Interfaces:**
- Produces: `IAuthService` (đăng ký, yêu cầu OTP, xác thực OTP, kích hoạt). Task 5 dùng lại phần OTP.

**Tiêu chí nghiệm thu:**
- Đăng ký hợp lệ → tài khoản `Pending`; giá trị lưu trong DB là hash, khác mật khẩu gốc.
- Username / email / số điện thoại trùng → `409`.
- Yêu cầu OTP → response chỉ có `otpId`, `expiresAt`; **không** có trường chứa mã OTP. *(Review Focus 5)*
- OTP sai → `422`. OTP đúng + kích hoạt → tài khoản `Active`.
- Yêu cầu OTP lần 2 → OTP lần 1 không còn dùng được.

- [ ] Cài đặt luồng đăng ký → OTP → kích hoạt; OTP chỉ ghi log ở môi trường Development.
- [ ] Viết test cho 5 tiêu chí → xanh.
- [ ] Commit: `feat(auth): registration and OTP activation`

### Task 4: Đăng nhập & phiên làm việc (UC-02, FR-07)

**Kết quả:** Người dùng đăng nhập, nhận token và truy cập theo đúng vai trò; mọi lượt đăng nhập đều được ghi lại.

**Phạm vi:** `Features/Auth`, `Common/` (đọc người dùng hiện tại từ token). **Dữ liệu:** `sp_account_get_credentials`, `sp_login_history_create`.

**Interfaces:**
- Produces: JWT với claim id tài khoản, username, vai trò; `ICurrentUser` trong `Common/` (id tài khoản, vai trò). Mọi task có phân quyền dùng `ICurrentUser`.

**Tiêu chí nghiệm thu:**
- Đúng thông tin + tài khoản `Active` → `200` + token; có dòng lịch sử `Successful` kèm IP và thiết bị.
- Sai mật khẩu → `401` với thông báo chung (không nói sai username hay mật khẩu); có dòng lịch sử `Failed`.
- Tài khoản `Pending` → bị từ chối.
- `GET /api/auth/me` không token → `401`; có token → `200`, không có `password_hash`. *(Review Focus 5)*
- Token hết hạn → `401`.

- [ ] Cài đặt đăng nhập, phát token, cấu hình xác thực JWT (authentication trước authorization).
- [ ] Viết test → xanh.
- [ ] Khoá endpoint ghi của chi nhánh (chuẩn bị cho Task 8) bằng vai trò Admin.
- [ ] Commit: `feat(auth): login, JWT session and login history`

### Task 5: Quản lý mật khẩu (UC-03)

**Kết quả:** Người dùng đổi mật khẩu khi đã đăng nhập, hoặc đặt lại khi quên.

**Phạm vi:** `Features/Auth`. **Dữ liệu:** `sp_account_change_password`, `sp_account_reset_password`, OTP mục đích `PasswordReset`.

**Tiêu chí nghiệm thu:**
- Đổi mật khẩu với mật khẩu cũ sai → bị từ chối.
- Đổi thành công → mật khẩu cũ không đăng nhập được, mật khẩu mới đăng nhập được.
- Đặt lại mật khẩu sau khi xác thực OTP `PasswordReset` → đăng nhập được bằng mật khẩu mới.
- Đặt lại khi chưa xác thực OTP → bị từ chối.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(auth): change and reset password`

### Task 6: Hồ sơ khách hàng (UC-04, UC-05)

**Kết quả:** Khách hàng quản lý hồ sơ của mình; nhân viên tra cứu khách hàng.

**Phạm vi:** `Features/Users`. **Dữ liệu:** `sp_create_customer_profile`, `sp_customer_get_profile`, `sp_customer_update_profile`, `sp_customer_search`, `sp_customer_get_summary`, `sp_customer_assign_branch`, `sp_account_change_image`.

**Interfaces:**
- Produces: `IUserService` có khả năng "lấy mã khách hàng (CIF) của tài khoản đang đăng nhập". Accounts, Transactions, Loans, Savings dùng nó để biết người gọi là khách hàng nào.

**Tiêu chí nghiệm thu:**
- Khách hàng đã kích hoạt tạo hồ sơ (một lần) → nhận CIF; xem và sửa `/api/customers/me`; đổi ảnh đại diện.
- Thông tin nhạy cảm (email, số điện thoại, CCCD) trả về dạng đã che.
- Khách hàng gọi tổng quan của khách hàng khác → `403`. *(Review Focus 2)*
- Nhân viên tìm theo CCCD hoặc họ tên → thấy kết quả; khách hàng gọi tìm kiếm → `403`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(users): customer profile and staff lookup`

### Task 7: Quản lý nhân viên (UC-06)

**Kết quả:** Admin tuyển nhân viên vào hệ thống và quản lý chức vụ, trạng thái, chi nhánh.

**Phạm vi:** `Features/Users`. **Dữ liệu:** `sp_admin_create_employee_account`, `sp_employee_create_profile`, `sp_employee_get_profile`, `sp_employee_update_profile`, `sp_employee_update_position`, `sp_employee_update_status`, `sp_employee_assign_branch`, `sp_employee_search`.

**Tiêu chí nghiệm thu:**
- Admin tạo tài khoản + hồ sơ nhân viên → nhân viên đăng nhập được với vai trò `Employee`.
- Đổi chức vụ (vd `Teller` → `Loan Officer`), trạng thái, chi nhánh → phản ánh đúng khi xem lại.
- Khách hàng hoặc nhân viên gọi các thao tác quản lý → `403`.
- Nhân viên xem và sửa hồ sơ của chính mình.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(users): employee management`

### Task 8: Quản lý chi nhánh (UC-07)

**Kết quả:** Admin mở, sửa, đóng chi nhánh; nhân viên xem tổng quan chi nhánh.

**Phạm vi:** `Features/Branches`. **Dữ liệu:** `sp_branch_create`, `sp_branch_update`, `sp_branch_update_status`, `sp_branch_get_summary`.

**Tiêu chí nghiệm thu:**
- Admin tạo chi nhánh → `201`, có trong danh sách công khai.
- Admin đóng chi nhánh → trạng thái `Closed`.
- Không phải Admin → `403` với mọi thao tác ghi.
- Nhân viên / Admin xem tổng quan chi nhánh; khách hàng → `403`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(branches): branch administration`

---

## M2 — Core Banking (MVP)

### Task 9: Tài khoản ngân hàng (UC-08, UC-09)

**Kết quả:** Khách hàng mở và xem tài khoản của mình; nhân viên đóng băng hoặc đóng tài khoản.

**Phạm vi:** `Features/Accounts`, `Domain/BankingAccount`. **Dữ liệu:** `sp_bank_account_create`, `sp_bank_account_get_details`, `sp_bank_account_search`, `sp_bank_account_update_status`.

**Interfaces:**
- Consumes: `ICurrentUser` (Task 4), `IUserService` (Task 6).
- Produces: `IAccountService.EnsureOwnedAsync(bankAccountId)`: ném lỗi `403` nếu tài khoản không thuộc khách hàng đang đăng nhập. Task 10, 11, 13, 16 dùng.

**Tiêu chí nghiệm thu:**
- Mở tài khoản (loại + tiền tệ) → `Active`, số tài khoản là chuỗi 20 chữ số, giữ số 0 ở đầu.
- Khách hàng chỉ thấy tài khoản của mình trong danh sách.
- Xem tài khoản của người khác → `403`. *(Review Focus 2)*
- Nhân viên đóng băng → `Frozen`; khách hàng tự đổi trạng thái → `403`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(accounts): open and manage banking accounts`

### Task 10: Nạp, rút tiền & lịch sử giao dịch (UC-10, UC-13)

**Kết quả:** Giao dịch viên nạp tiền cho khách; khách hàng rút tiền và xem lịch sử giao dịch.

**Phạm vi:** `Features/Transactions`, `Domain/Transaction`. **Dữ liệu:** `sp_bank_transaction_deposit`, `sp_bank_transaction_withdraw`, `sp_bank_transaction_search`, `sp_bank_transaction_get_details`.

**Interfaces:**
- Consumes: `IAccountService.EnsureOwnedAsync` (Task 9).

**Tiêu chí nghiệm thu:**
- Nhân viên nạp 1.000.000 → số dư tăng đúng 1.000.000.
- Khách hàng rút tiền từ tài khoản của mình → số dư giảm đúng; rút từ tài khoản người khác → `403`.
- Rút vượt số dư khả dụng → `409`, số dư không đổi.
- Số tiền `0`, âm, hoặc `100.005` → `400`, chưa chạm DB. *(Review Focus 3)*
- Hai lệnh rút song song, tổng vượt số dư → đúng một lệnh thành công, số dư khả dụng không âm. *(Review Focus 1)*
- Lịch sử lọc được theo loại, trạng thái, khoảng ngày, có phân trang; xem lịch sử tài khoản người khác → `403`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(transactions): deposit, withdraw and history`

### Task 11: Chuyển khoản & thanh toán (UC-11, UC-12)

**Kết quả:** Khách hàng chuyển tiền nội bộ và thanh toán an toàn, kể cả khi nhiều lệnh chạy cùng lúc.

**Phạm vi:** `Features/Transactions`. **Dữ liệu:** `sp_bank_transaction_transfer`, `sp_bank_transaction_payment`.

**Cần quyết trước khi làm:** có bắt xác nhận lại bằng OTP / mật khẩu khi chuyển tiền không? Hiện proc chưa hỗ trợ (cần cột `consumed` + proc tiêu thụ OTP). Mặc định: chưa làm, ghi vào giới hạn (system_design §10).

**Tiêu chí nghiệm thu:**
- Chuyển thành công → nguồn giảm (số tiền + phí), đích tăng (số tiền), có giao dịch `Successful`.
- Tài khoản nguồn không thuộc người gọi → `403`. *(Review Focus 2)*
- Không đủ số dư → `409`, `error.code = 250040`, không số dư nào thay đổi.
- Hai tài khoản khác loại tiền → bị từ chối. Nguồn trùng đích → `400`.
- Tài khoản A có 1.000.000, bắn song song 20 lệnh chuyển 100.000 → đúng 10 thành công, 10 lỗi `250040`; số dư khả dụng của A = 0; tổng tiền vào các tài khoản đích = 1.000.000. *(Review Focus 1)*
- Thanh toán trừ đúng số tiền từ tài khoản nguồn.

- [ ] Chốt quyết định xác nhận OTP (ghi vào PLAN).
- [ ] Cài đặt → viết test (gồm test đồng thời) → xanh.
- [ ] Commit: `feat(transactions): transfer and payment`

### Task 12: Người thụ hưởng (UC-14)

**Kết quả:** Khách hàng lưu người nhận thường xuyên và chuyển tiền nhanh cho họ.

**Phạm vi:** `Features/Transactions`. **Dữ liệu:** `sp_beneficiary_create`, `sp_beneficiary_update`, `sp_beneficiary_get_details`, `sp_beneficiary_search`.

**Tiêu chí nghiệm thu:**
- Lưu, sửa, xem người thụ hưởng; danh sách chỉ gồm người thụ hưởng của mình.
- Không lưu được tài khoản của chính mình làm người thụ hưởng.
- Xem người thụ hưởng của khách hàng khác → `403` / `404`.
- Chuyển khoản tới người thụ hưởng đã lưu → thành công như Task 11.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(transactions): beneficiaries`

---

## M3 — Sản phẩm

### Task 13: Thẻ (UC-15)

**Kết quả:** Khách hàng phát hành và khoá thẻ cho tài khoản của mình.

**Phạm vi:** `Features/Cards`. **Dữ liệu:** `sp_card_create`, `sp_card_get_details`, `sp_card_search`, `sp_card_update_status`.

**Tiêu chí nghiệm thu:**
- Phát hành thẻ cho tài khoản của mình → response có số thẻ đầy đủ, hợp lệ theo Luhn.
- Mọi lần xem sau → số thẻ dạng `400000******1234`. *(Review Focus 5)*
- Phát hành cho tài khoản của người khác → `403`. *(Review Focus 2)*
- Khoá thẻ → `Blocked`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(cards): issue and block cards`

### Task 14: Vòng đời khoản vay (UC-16, UC-17, UC-18 phần trả nợ)

**Kết quả:** Khách hàng vay vốn; Loan Officer duyệt và giải ngân; khách hàng trả nợ đến khi tất toán.

**Phạm vi:** `Features/Loans`. **Dữ liệu:** `sp_loan_apply`, `sp_loan_review`, `sp_loan_disburse`, `sp_loan_repay`, `sp_loan_get_details`, `sp_loan_search`.

**Tiêu chí nghiệm thu:**
- Đăng ký vay → `Pending`.
- Nhân viên không phải `Loan Officer` duyệt → `403`. Loan Officer duyệt → `Approved`; từ chối → `Rejected`, không giải ngân được.
- Giải ngân vào tài khoản `Active` của khách hàng → `Disbursed`, số dư tài khoản tăng đúng số tiền vay.
- Trả một kỳ → dư nợ giảm; trả hết → `Closed`.
- Khách hàng chỉ thấy khoản vay của mình; xem khoản vay người khác → `403`. *(Review Focus 2)*

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(loans): loan lifecycle`

### Task 15: Lịch trả góp (UC-18)

**Kết quả:** Khách hàng xem lịch trả góp từng kỳ, khớp với số tiền góp mà ngân hàng tính.

**Phạm vi:** `Features/Loans/AmortizationSchedule` (logic thuần, không chạm DB) + endpoint `GET /api/loans/{id}/schedule`.

**Tiêu chí nghiệm thu** (unit test, công thức BR-10):
- Vay 12.000.000, lãi 12%/năm, 12 tháng → 12 kỳ; tổng tiền gốc = 12.000.000; dư nợ kỳ cuối = 0.
- Tiền góp hằng tháng bằng giá trị proc `sp_loan_apply` tính cho cùng đầu vào.
- Lãi 0% → mỗi kỳ = gốc / số tháng (kỳ cuối gánh phần lẻ).
- Số tháng ≤ 0 → bị từ chối.
- Endpoint: chủ khoản vay xem được; người khác → `403`.

- [ ] Cài đặt → viết unit test → xanh; thêm integration test cho endpoint.
- [ ] Commit: `feat(loans): amortization schedule`

### Task 16: Tiết kiệm (UC-19)

**Kết quả:** Khách hàng gửi tiết kiệm có kỳ hạn và tất toán.

**Phạm vi:** `Features/Savings`. **Dữ liệu:** `sp_saving_account_open`, `sp_saving_account_close`, `sp_saving_account_get_details`, `sp_saving_account_search`.

**Tiêu chí nghiệm thu:**
- Mở sổ từ tài khoản của mình → tài khoản nguồn giảm đúng số tiền gửi, sổ `Active`.
- Tất toán trước hạn → chỉ nhận lại gốc.
- Tất toán sổ đã đáo hạn → nhận gốc + lãi đơn (BR-11).
- Mở sổ từ tài khoản người khác / xem sổ người khác → `403`. *(Review Focus 2)*

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(savings): open and close saving accounts`

### Task 17: Tự động đáo hạn (UC-20)

**Kết quả:** Sổ tiết kiệm tới hạn tự chuyển sang `Matured` mỗi ngày, không cần ai thao tác.

**Phạm vi:** `Features/Savings/MaturitySettlementJob` (`BackgroundService`). **Dữ liệu:** `sp_saving_account_settle_matured`.

**Tiêu chí nghiệm thu:**
- Sổ có ngày đáo hạn ≤ hôm nay → `Matured` sau khi job chạy.
- Job chạy 2 lần liên tiếp → kết quả không đổi.
- Job gặp lỗi → ghi log, API vẫn phục vụ request bình thường.
- Lịch chạy: 00:05 giờ Việt Nam hằng ngày.

- [ ] Cài đặt → viết test cho phần gọi proc của job → xanh; kiểm tay với chu kỳ rút ngắn.
- [ ] Commit: `feat(savings): daily maturity settlement job`

---

## M4 — Vận hành

### Task 18: Thông báo (UC-21)

**Kết quả:** Khách hàng nhận thông báo khi giao dịch hoặc giải ngân thành công, và quản lý hộp thư thông báo.

**Phạm vi:** `Features/Notifications`; gắn vào `Transactions` (Task 11) và `Loans` (Task 14). **Dữ liệu:** `sp_notification_create`, `sp_notification_search`, `sp_notification_get_details`, `sp_notification_mark_is_read`.

**Interfaces:**
- Produces: `INotificationService.NotifyAsync(accountId, type, message)`, chạy best-effort.

**Tiêu chí nghiệm thu:**
- Chuyển khoản thành công → người chuyển có thông báo mới.
- Gửi thông báo lỗi (giả lập service ném lỗi) → chuyển khoản vẫn `200`, lỗi có trong log (BR-13).
- Xem danh sách chưa đọc, đánh dấu đã đọc.
- Xem thông báo của người khác → `403` / `404`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(notifications): transaction notifications and inbox`

### Task 19: Khoá tài khoản & lịch sử đăng nhập (UC-22, UC-23)

**Kết quả:** Admin khoá / mở khoá người dùng có hiệu lực ngay; người dùng và Admin xem lịch sử đăng nhập.

**Phạm vi:** `Features/Admin`, `Features/Auth` (kiểm tra trạng thái khi xác thực token). **Dữ liệu:** `sp_admin_update_account_status`, `sp_login_history_search`.

**Tiêu chí nghiệm thu:**
- Admin khoá tài khoản → tài khoản đó không đăng nhập được.
- Token cấp trước khi bị khoá → request kế tiếp `401`. *(Review Focus 4)*
- Mở khoá → đăng nhập lại được.
- Khách hàng chỉ xem lịch sử đăng nhập của mình; Admin xem của mọi người.
- Không phải Admin gọi khoá / mở khoá → `403`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(admin): account locking and login history`

### Task 20: Thống kê (UC-24)

**Kết quả:** Admin xem số liệu tổng quan về khách hàng và chi nhánh.

**Phạm vi:** `Features/Admin`. **Dữ liệu:** `vw_CustomerStatistics`, `sp_branch_get_summary`.

**Tiêu chí nghiệm thu:**
- Admin nhận số liệu thống kê khớp với dữ liệu seed.
- Không phải Admin → `403`.

- [ ] Cài đặt → viết test → xanh.
- [ ] Commit: `feat(admin): statistics dashboard data`

---

## M5 — Sẵn sàng triển khai

### Task 21: Bảo mật nâng cao

**Kết quả:** Hệ thống chịu được dò mật khẩu và lạm dụng API; OTP gửi qua kênh thật.

**Tiêu chí nghiệm thu:**
- Sai mật khẩu 5 lần trong 15 phút → tạm chặn đăng nhập tài khoản đó.
- Vượt giới hạn request → `429`.
- OTP gửi qua email (SMTP cấu hình bằng biến môi trường); ngoài Development, mã OTP không xuất hiện trong log.
- Rà soát: không có secret trong git; mọi endpoint có id tài nguyên đều kiểm tra quyền sở hữu (đối chiếu api_contract §3).
- Load test 100 người dùng đồng thời trên luồng đăng nhập + chuyển khoản: 95% request dưới 2 giây (NFR-05), không số dư nào âm.

- [ ] Cài đặt → viết test → xanh; chạy rà soát bảo mật.
- [ ] Commit: `feat(security): login throttling, rate limiting, email OTP`

### Task 22: Đóng gói & CI

**Kết quả:** Ai cũng chạy được toàn bộ hệ thống bằng Docker; mỗi lần push đều được kiểm tra tự động.

**Phạm vi:** `BankingSystem.Api/Dockerfile`, service `api` trong `docker-compose.yml`, `.github/workflows/ci.yml` (theo pipeline.md §4).

**Tiêu chí nghiệm thu:**
- `docker compose up` chạy cả API và SQL Server; sau `deploy.ps1 -Docker -Seed`, `GET /api/branches` qua cổng 8080 → `200`.
- Secret truyền qua biến môi trường, không nằm trong image.
- CI chạy build → dựng DB → test → docker build, xanh trên `master`.

- [ ] Viết Dockerfile + cập nhật compose → kiểm tay.
- [ ] Viết workflow CI → push → xanh.
- [ ] Cập nhật README phần "Chạy bằng Docker".
- [ ] Commit: `ci: dockerize api and add CI pipeline`

---

## M6 — Mở rộng quy mô

> Chỉ bắt đầu sau Task 22. Load test ở Task 21 phải chạy trước để biết nút thắt nằm ở đâu: nếu SQL Server là chỗ nghẽn thì thêm bản API hay message queue không làm hệ thống nhanh hơn. Hai task dưới đây là bài học kiến trúc có chủ đích, không phải yêu cầu của SRS.

### Task 23: Load balancer & nhiều bản API

**Kết quả:** Chạy từ 2 bản API trở lên sau một load balancer; mất một bản thì hệ thống vẫn phục vụ.

**Phạm vi:** `docker-compose.yml` (thêm `nginx`, chạy `api` nhiều bản), `nginx.conf`.

**Điều kiện:** API không giữ trạng thái trong bộ nhớ (JWT, không session), nên thêm bản chỉ là chạy thêm container. Cần kiểm tra lại: JWT secret lấy từ biến môi trường và giống nhau ở mọi bản; `MaturitySettlementJob` (Task 17) chạy đồng thời ở mọi bản mà kết quả không đổi.

**Tiêu chí nghiệm thu:**
- `docker compose up --scale api=2`: 20 request liên tiếp tới cổng 8080 được chia cho cả hai bản (nhìn qua log hoặc header tên bản).
- Dừng một bản API → request vẫn `200`.
- Token cấp ở bản 1 dùng được ở bản 2.
- Job đáo hạn chạy trên hai bản cùng lúc → kết quả không đổi.
- Chạy lại load test của Task 21: không số dư nào âm; ghi lại số đo trước và sau để biết LB có giúp hay không.

- [ ] Cập nhật compose + viết `nginx.conf` → kiểm tay các tiêu chí trên.
- [ ] Ghi số đo trước/sau của load test vào `docs/`.
- [ ] Commit: `feat(infra): nginx load balancer with two api instances`

### Task 24: Message queue cho thông báo

**Kết quả:** Gửi thông báo (và email OTP) không làm chậm hay làm hỏng giao dịch; thông báo không mất khi API khởi động lại.

**Phạm vi:** `Features/Notifications` (đầu gửi + `BackgroundService` đầu nhận), service RabbitMQ trong `docker-compose.yml`. Giữ nguyên `INotificationService.NotifyAsync` của Task 18, chỉ đổi phần cài đặt bên trong nên Transactions và Loans không phải sửa.

**Không đưa vào queue:** nạp, rút, chuyển khoản, thanh toán. Mỗi request vẫn đúng một lần gọi proc và trả kết quả ngay (system_design §7.3); đưa vào queue sẽ phải thêm trạng thái "đang xử lý" và xử lý trùng lệnh.

**Tiêu chí nghiệm thu:**
- Chuyển khoản thành công → response không chờ thông báo; thông báo xuất hiện sau vài giây.
- Dừng bên nhận, chuyển khoản, bật lại → thông báo vẫn được tạo (queue bền vững).
- RabbitMQ không chạy → chuyển khoản vẫn `200`, lỗi có trong log (BR-13).
- Xử lý một message lỗi quá số lần thử lại → vào dead-letter queue, không chặn các message sau.
- Giới hạn đã biết: queue giao ít nhất một lần nên hiếm khi trùng thông báo; ghi vào system_design §10.

- [ ] Thêm RabbitMQ vào compose; cài đặt → viết test → xanh.
- [ ] Ghi giới hạn vào `docs/system_design.md` §10.
- [ ] Commit: `feat(notifications): publish notifications through message queue`

---

## M7 — Middleware pipeline

> Hệ thống có 6 middleware (ngoài exception handler đã làm ở Task 2). Hai cái đã có task riêng: JWT Authentication ở Task 4, rate limiting ở Task 21. Bốn cái còn lại là Task 25–28. Không cần chờ M6: làm được bất cứ lúc nào sau Task 2; riêng CORS phải xong trước khi nối frontend. Middleware tự viết là class có `private readonly RequestDelegate _next`, constructor tường minh và `InvokeAsync(HttpContext context)` (AGENTS.md §3 quy tắc 9).

| # | Middleware | Loại | Làm ở |
|---|---|---|---|
| 1 | Correlation ID | tự viết | Task 25 |
| 2 | Request logging | tự viết | Task 26 |
| 3 | Security headers | tự viết | Task 27 |
| 4 | CORS | có sẵn | Task 28 |
| 5 | JWT Authentication | có sẵn | Task 4 |
| 6 | Rate limiting | có sẵn | Task 21 |

**Thứ tự đăng ký trong `Program.cs`** (sai thứ tự là lỗi, xem [`docs/pipeline.md`](docs/pipeline.md) §1):

`Correlation ID` → `Request logging` → `UseExceptionHandler` → `Security headers` → `UseHttpsRedirection` → `CORS` → `Rate limiting` → `Authentication` → `Authorization` → `MapControllers`

- Correlation ID đứng đầu để mọi log và mọi lỗi phía sau đều có mã truy vết.
- Request logging nằm ngoài exception handler để ghi được status cuối cùng (kể cả `500`).
- CORS đứng trước Authentication để preflight `OPTIONS` (không mang token) không bị `401`.
- Rate limiting đứng trước Authentication để chặn dò mật khẩu trước khi tốn công kiểm token.

### Task 25: Correlation ID

**Kết quả:** Mỗi request có một mã truy vết, trả về trong response và có mặt trong mọi dòng log của request đó.

**Phạm vi:** `Common/CorrelationIdMiddleware.cs`, `Program.cs`.

**Tiêu chí nghiệm thu:**
- Request không có header `X-Correlation-Id` → response có header đó với giá trị mới (GUID).
- Request có header hợp lệ → response trả lại đúng giá trị.
- Giá trị dài quá 64 ký tự hoặc có ký tự ngoài chữ, số, `-` → bỏ qua và tạo mã mới (chống chèn nội dung giả vào log).
- Response lỗi (`404`, `500`) cũng có header.

- [ ] Cài đặt middleware, đưa mã vào log scope (`ILogger.BeginScope`) → viết test → xanh.
- [ ] Commit: `feat(common): correlation id middleware`

### Task 26: Request logging

**Kết quả:** Mỗi request để lại đúng một dòng log: method, path, status code, thời gian xử lý.

**Phạm vi:** `Common/RequestLoggingMiddleware.cs`, `Program.cs`.

**Tiêu chí nghiệm thu:**
- Request thành công → có một dòng log dạng `GET /api/branches -> 200 in 12ms`.
- Request làm exception handler bắt lỗi → dòng log có status `500`. *(vì middleware nằm ngoài exception handler)*
- Log không chứa body, header `Authorization` hay query string. *(Review Focus 5)*

- [ ] Cài đặt (đo thời gian bằng `Stopwatch`) → viết test → xanh.
- [ ] Commit: `feat(common): request logging middleware`

### Task 27: Security headers

**Kết quả:** Mọi response mang header bảo mật cơ bản; dữ liệu tài chính không bị trình duyệt hay proxy cache.

**Phạm vi:** `Common/SecurityHeadersMiddleware.cs`, `Program.cs`.

**Tiêu chí nghiệm thu:**
- Mọi response (kể cả `404` và `500`) có: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store`.
- Swagger vẫn mở được ở Development.

- [ ] Cài đặt (gắn header qua `Response.OnStarting` để không bị mất khi có lỗi) → viết test → xanh.
- [ ] Commit: `feat(common): security headers middleware`

### Task 28: CORS

**Kết quả:** Chỉ frontend được cấu hình mới gọi được API từ trình duyệt, và đọc được các header tuỳ chỉnh.

**Phạm vi:** `Program.cs`, `appsettings.json` (`Cors:AllowedOrigins`).

**Tiêu chí nghiệm thu:**
- Preflight `OPTIONS` từ origin trong danh sách → `Access-Control-Allow-Origin` trả đúng origin đó.
- Origin lạ → không có header `Access-Control-Allow-Origin`.
- Không dùng `AllowAnyOrigin`; danh sách origin lấy từ cấu hình, không viết cứng trong code.
- Header `X-Total-Count` và `X-Correlation-Id` nằm trong `Access-Control-Expose-Headers`, nếu không frontend không đọc được tổng số bản ghi.

- [ ] Cấu hình policy + danh sách origin → viết test → xanh.
- [ ] Commit: `feat(common): cors policy for frontend`
