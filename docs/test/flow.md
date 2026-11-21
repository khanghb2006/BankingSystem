# Test: luồng đủ và bảo mật xuyên suốt

Liên quan: [`README.md`](README.md) · [`register.md`](register.md) · [`otp.md`](otp.md) · [`verify.md`](verify.md) · [`activate.md`](activate.md).

## 1. Luồng đủ (UC-01)

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| FLOW-01 | `register` → `otp` (Register) → `otp/verify` (mã đọc từ DB) → `activate` | Mọi bước `200`. Trạng thái tài khoản (đọc từ DB hoặc response): sau `register` là `Pending`, sau `otp` vẫn `Pending`, sau `verify` vẫn `Pending`, sau `activate` là `Active` | ★ | [ ] |
| FLOW-02 | Sau FLOW-01, đăng ký lại cùng username | `409`, `140000` (tài khoản đã kích hoạt vẫn giữ username) | ○ | [ ] |

## 2. Định dạng response

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| FLOW-03 | Mọi response lỗi của 4 endpoint (`400`, `409`, `422`, `404`) | Đúng envelope `{ success: false, message, data: null, error: { code, domain } }`, không phải ProblemDetails mặc định của ASP.NET | ○ | [ ] |
| FLOW-04 | Mọi response (cả thành công và lỗi) | Có header `X-Correlation-Id` (từ Task 25) | ○ | [ ] |

## 3. Rò rỉ OTP qua log

Cần dựng factory ở môi trường tương ứng và bắt log (ví dụ qua một `ILoggerProvider` ghi vào danh sách trong bộ nhớ). Tốn công hơn các ca khác nên để tuỳ chọn.

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| FLOW-05 | Môi trường **Development**, xin OTP | Log có một dòng chứa mã OTP (kênh giao đang chạy) | ◇ | [ ] |
| FLOW-06 | Môi trường **Production**, xin OTP | **Không dòng log nào** chứa mã OTP | ◇ | [ ] |

> Lưu ý thiết kế: `AuthService` phụ thuộc trực tiếp vào lớp `AuthRepository` chứ không phải interface, nên không thể thay repository giả để test riêng `AuthService`. FLOW-05 và FLOW-06 vì thế phải chạy qua cả DB thật.
