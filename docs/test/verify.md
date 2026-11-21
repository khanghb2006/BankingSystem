# Test: `POST /api/auth/otp/verify`

Liên quan: [`README.md`](README.md) · proc `dbo.sp_otp_verify` · DTO `VerifyOtpRequestDto`.

**Luật của DTO:** `accountId` ≥ 1 · `otpCode` đúng 6 chữ số (`^[0-9]{6}\z`) · `purpose` chỉ `Register` hoặc `PasswordReset`.

**Hành vi của proc:** chỉ đánh dấu OTP là `verified`, **không** kích hoạt tài khoản. Chấp nhận mã khi khớp (tài khoản, mã, purpose) và chưa verify và chưa hết hạn. Mã lỗi: 122000 tài khoản không tồn tại, 122001 mã sai hoặc hết hạn, 122002 cập nhật thất bại (dải `otp` → `422`).

**Tiền điều kiện:** tài khoản đã đăng ký và đã xin OTP `Register`; mã đọc từ bảng `OTP` bằng hàm hỗ trợ của test.

## 1. Thành công

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| VER-01 | Mã đúng, đúng purpose | `200`, trả `AccountResponseDto`, `status` **vẫn là `Pending`** (verify không tự kích hoạt); bản ghi OTP có `verified = 1` | ★ | [ ] |

## 2. Mã sai hoặc không dùng được → lỗi OTP

Mọi ca: `error.code = 122001`, `error.domain = "otp"`. ⚠ HTTP `422` theo tiêu chí PLAN nhưng hiện ra `404` (xem [`README.md`](README.md), mục "Cần chốt" số 1).

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| VER-02 | Mã sai (6 số khác mã thật) | `422`, `122001`, tài khoản vẫn `Pending`, OTP vẫn `verified = 0` | ★ ⚠ | [ ] |
| VER-04 | Mã hết hạn (test ép `expired_at` về quá khứ rồi verify mã đúng) | `122001` | ★ ⚠ | [ ] |
| VER-05 | Dùng lại mã đã verify thành công | `122001` (chống replay) | ★ ⚠ | [ ] |
| VER-06 | Xin OTP lần 2, rồi verify bằng mã lần 1; sau đó verify bằng mã lần 2 | Mã lần 1: `122001`. Mã lần 2: `200` | ★ ⚠ | [ ] |
| VER-07 | Mã đúng nhưng purpose khác (xin `Register`, verify `PasswordReset`) | `122001` | ★ ⚠ | [ ] |
| VER-08 | Mã đúng của tài khoản B nhưng gửi kèm `accountId` của A | `122001`; OTP của B không bị đánh dấu verified | ★ ⚠ | [ ] |

## 3. Dữ liệu sai → `400` (không chạm DB)

Mọi ca: `400`, `error.domain = "validation"`.

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| VER-03 | Mã sai định dạng: 5 số; 7 số; có chữ (`12345a`); `123456abc`; `123456` kèm xuống dòng cuối; rỗng | `400` cho tất cả (chứng minh không bị SQL Server âm thầm cắt về 6 ký tự) | ★ | [ ] |
| VER-09 | Purpose ngoài danh sách (`Transaction`); `accountId` bằng 0 hoặc âm; thiếu field | `400` | ○ | [ ] |

## 4. Lỗi nghiệp vụ khác

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| VER-10 | `accountId` không tồn tại | Lỗi 122000. ⚠ `404` (message có `does not exist`) hay `422` (theo dải) | ○ | [ ] |
| VER-11 | Tài khoản chưa từng xin OTP, verify mã bất kỳ | `122001` | ○ | [ ] |

## 5. Bảo mật

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| VER-12 | Response lỗi của VER-02 | Không echo lại mã đã gửi trong `message` | ○ | [ ] |
