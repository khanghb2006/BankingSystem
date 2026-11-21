# Test Task 3 — Đăng ký và kích hoạt tài khoản (UC-01)

Danh sách ca test để **đối chiếu khi viết code test**. Mỗi file một endpoint, mỗi dòng một ca có mã riêng. Viết xong test nào thì đánh dấu `[x]` ở cột **Test** của ca đó.

Nguồn: [`PLAN.md`](../../PLAN.md) Task 3 · [`api_contract.md`](../api_contract.md) §1.10, §2, §3 · các proc trong [`database/src/account/auth/`](../../database/src/account/auth/) và [`database/src/otp/`](../../database/src/otp/).

| File | Endpoint | Mã ca |
|---|---|---|
| [`register.md`](register.md) | `POST /api/auth/register` | `REG-xx` |
| [`otp.md`](otp.md) | `POST /api/auth/otp` | `OTP-xx` |
| [`verify.md`](verify.md) | `POST /api/auth/otp/verify` | `VER-xx` |
| [`activate.md`](activate.md) | `POST /api/auth/activate` | `ACT-xx` |
| [`flow.md`](flow.md) | Luồng đủ và bảo mật xuyên suốt | `FLOW-xx` |

## Ký hiệu

| Ký hiệu | Nghĩa |
|---|---|
| ★ | Bắt buộc: tiêu chí nghiệm thu của PLAN hoặc rủi ro bảo mật |
| ○ | Nên có |
| ◇ | Tuỳ chọn, tốn công hơn hoặc có thể lộ lỗi thật |
| ⚠ | Kỳ vọng còn phụ thuộc quyết định ở mục "Cần chốt" bên dưới |

## Quy ước chung cho mọi test

- Integration test dùng `WebApplicationFactory<Program>` và DB thật, dựng bằng `pwsh -File database/deploy.ps1 -Seed` (AGENTS.md §3 quy tắc 10).
- **Dữ liệu mới cho mỗi test.** DB giữ nguyên giữa các lần `dotnet test`, nên username, email, số điện thoại phải sinh ngẫu nhiên (ví dụ ghép `Guid`). Username chỉ gồm chữ, số, `_`, `.` (3–50 ký tự); số điện thoại 9–20 chữ số.
- **Envelope.** Mọi response đều là `{ success, message, data, error: { code, domain } }`. Test kiểm `success` và `error.code`/`error.domain`, không chỉ kiểm mã HTTP.
- **Hàm hỗ trợ cần có** (trong `BankingSystem.Tests`, không có trong code API):
  - đọc mã OTP mới nhất chưa verify của một tài khoản từ bảng `OTP` (response không trả mã);
  - ép `expired_at` của OTP về quá khứ (cho ca hết hạn);
  - đọc `password_hash` của một tài khoản.
- **Mọi lỗi nghiệp vụ** trả HTTP theo `SqlErrorCatalog`: dải 11xxxx–15xxxx → `409`, dải 121xxx–122xxx → `422`. Lỗi validation DTO → `400`, `error.domain = "validation"`, `error.code = 400`.

## Ánh xạ tiêu chí nghiệm thu của PLAN → ca test

| Tiêu chí (PLAN Task 3) | Ca test |
|---|---|
| Đăng ký hợp lệ → `Pending`; giá trị lưu là hash, khác mật khẩu gốc | REG-01, REG-02 |
| Username / email / số điện thoại trùng → `409` | REG-05, REG-06, REG-07 |
| Yêu cầu OTP → response chỉ có `otpId`, `expiresAt`, không có mã | OTP-01, OTP-02 |
| OTP sai → `422`; OTP đúng + kích hoạt → `Active` | VER-02, VER-01, ACT-01, FLOW-01 |
| Yêu cầu OTP lần 2 → OTP lần 1 không còn dùng được | OTP-03, VER-06 |

## Cần chốt trước khi viết (đánh dấu ⚠)

1. **OTP sai → `422` hay `404`.** [`ApiExceptionHandler.cs:39`](../../BankingSystem.Api/Common/ApiExceptionHandler.cs) ép mọi message chứa `Invalid` thành `404`. Thông báo của 122001 là `Invalid or Expired OTP code.`, nên hiện ra `404`, trái với tiêu chí `422`. Hướng đề xuất: bỏ luật 404 này cho domain `otp`.
2. **Tài khoản không tồn tại.** 121000 (`Invalid account ID.`), 122000 (`Account does not exist.`), 110000 (`Invalid account ID.`) hiện đều ra `404`. Nếu sửa theo ý 1, hai ca OTP có thể đổi sang `422`. Chốt một bảng kỳ vọng rồi mới viết.
3. **Hàm hỗ trợ đọc DB trong test cần `Microsoft.Data.SqlClient` trực tiếp**, vì `StoredProcedureExecutor` chỉ gọi proc, không chạy được `SELECT`/`UPDATE`. Quy tắc "chỉ `Data/` dùng SqlClient" hiểu là cho `BankingSystem.Api`; helper này chỉ nằm trong `BankingSystem.Tests`. Cần xác nhận cách hiểu này.

## Không test ở Task 3

- Dò mã OTP bằng cách thử liên tục (1.000.000 tổ hợp, hạn 5 phút, chưa giới hạn số lần thử).
- Xin OTP hàng loạt cho tài khoản người khác (`accountId` tăng dần).

Hai việc này thuộc giới hạn tốc độ và khoá đăng nhập ở **Task 21**.
