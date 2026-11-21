# Test: `POST /api/auth/otp`

Liên quan: [`README.md`](README.md) · proc `dbo.sp_otp_generate_otpcode` · DTO `RequestOtpDto`, `OtpResponseDto` · kiểu nội bộ `IssuedOtp`.

**Luật của DTO:** `accountId` ≥ 1 · `purpose` bắt buộc và chỉ nhận `Register` hoặc `PasswordReset` (phân biệt hoa thường).

**Hành vi của proc:** sinh mã 6 chữ số, hạn 5 phút; OTP cũ cùng (tài khoản, purpose) còn hiệu lực bị cho hết hạn ngay; mã lỗi 121000 account sai, 121001 purpose sai, 121002 tạo thất bại (dải `otp` → `422`).

**Tiền điều kiện của mọi ca:** có một tài khoản đã đăng ký (xem [`register.md`](register.md) REG-01) để lấy `accountId`.

## 1. Thành công

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| OTP-01 | Xin OTP `Register` cho tài khoản vừa đăng ký | `200`, `success: true`, `data` có đúng hai key `otpId` và `expiresAt` | ★ | [ ] |
| OTP-02 | Soi body response của OTP-01 | Không có key `otpCode`/`otp_code`; chuỗi mã 6 số (đọc từ bảng `OTP`) **không xuất hiện ở bất kỳ đâu** trong body | ★ | [ ] |
| OTP-03 | Xin OTP lần 2 cho cùng tài khoản và purpose | `200`, `otpId` mới khác lần trước; mã lần 1 không còn dùng được (kiểm ở [`verify.md`](verify.md) VER-06) | ★ | [ ] |
| OTP-04 | `expiresAt` | Khoảng 5 phút sau thời điểm gọi (cho sai số vài giây); định dạng ngày không có offset | ○ | [ ] |
| OTP-05 | Xin OTP `PasswordReset` | `200` (purpose này được phép, Task 5 sẽ dùng) | ○ | [ ] |
| OTP-06 | Xin OTP cho hai tài khoản khác nhau | Mỗi tài khoản có OTP riêng, không ảnh hưởng nhau | ○ | [ ] |

## 2. Dữ liệu sai → `400` (không chạm DB)

Mọi ca: `400`, `success: false`, `error.domain = "validation"`.

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| OTP-07 | Purpose ngoài danh sách cho phép: `Transaction`, `Login`, `Verify Email`, `register` (viết thường), chuỗi rỗng | `400` cho tất cả; **không** có OTP mới nào được tạo trong DB | ★ | [ ] |
| OTP-08 | Thiếu `purpose` | `400` | ★ | [ ] |
| OTP-09 | `accountId` bằng 0; số âm; thiếu | `400` | ★ | [ ] |

## 3. Lỗi nghiệp vụ

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| OTP-10 | `accountId` không tồn tại | Lỗi 121000, `error.domain = "otp"`. ⚠ `404` (luật "Invalid → 404" hiện tại) hay `422` (theo dải) | ★ | [ ] |

## 4. Bảo mật

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| OTP-11 | Response lỗi (`400`, 121000) | Cũng không chứa mã OTP nào | ○ | [ ] |
| OTP-12 | Mã trong DB là 6 chữ số, có thể bắt đầu bằng `0` (giữ nguyên số 0 đầu) | Lấy ra dạng chuỗi, độ dài đúng 6 | ○ | [ ] |
