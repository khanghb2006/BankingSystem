# Test: `POST /api/auth/activate`

Liên quan: [`README.md`](README.md) · proc `dbo.sp_account_activate` · DTO `ActivateRequestDto`.

**Luật của DTO:** `accountId` ≥ 1.

**Hành vi của proc:** chỉ kích hoạt khi tài khoản đang `Pending` **và** có OTP `Register` đã `verified` còn hạn (`fn_otp_validate_verify`); kích hoạt xong thì xoá OTP đã dùng. Mã lỗi: 110000 `accountId` không hợp lệ, 110010 OTP chưa verify, 110020 kích hoạt thất bại (dải 11xxxx → `409`, domain `account`).

**Điểm cốt lõi:** an toàn của bước này dựa vào *trạng thái trong DB*, không dựa vào dữ liệu client gửi. Biết `accountId` không đủ để kích hoạt.

**Tiền điều kiện:** tài khoản đã đăng ký; tuỳ ca mà đã xin OTP, đã verify hay chưa.

## 1. Thành công

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| ACT-01 | Đã verify OTP `Register`, gọi activate | `200`, `data.status = "Active"`, `data.updatedAt` có giá trị | ★ | [ ] |
| ACT-02 | Sau ACT-01, đọc bảng `OTP` | Bản ghi OTP `Register` của tài khoản đã bị xoá | ○ | [ ] |

## 2. Không được kích hoạt khi bỏ qua OTP → `409`

Mọi ca: `409`, `error.code = 110010`, `error.domain = "account"`. Sau mỗi ca, tài khoản **vẫn `Pending`** (kiểm bằng DB).

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| ACT-03 | Đã xin OTP nhưng **chưa verify**, gọi activate | `409`, `110010` | ★ | [ ] |
| ACT-04 | Vừa đăng ký, **chưa xin OTP gì**, gọi activate | `409`, `110010` | ★ | [ ] |
| ACT-05 | Kích hoạt lần hai sau khi đã `Active` | `409`, `110010` (OTP đã bị xoá nên không còn bản ghi verified) | ★ | [ ] |
| ACT-06 | Dùng OTP đã verify của tài khoản B để kích hoạt tài khoản A | A: `409`, `110010`, vẫn `Pending`. B không bị ảnh hưởng | ★ | [ ] |
| ACT-07 | Đã verify nhưng để quá hạn rồi mới activate (test ép `expired_at` về quá khứ) | `409`, `110010` | ○ | [ ] |
| ACT-08 | Verify OTP purpose `PasswordReset` (không phải `Register`) rồi activate | `409`, `110010` (activate chỉ chấp nhận OTP `Register`) | ○ | [ ] |

## 3. Dữ liệu sai hoặc không tồn tại

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| ACT-09 | `accountId` bằng 0; số âm; thiếu field | `400`, `error.domain = "validation"` | ★ | [ ] |
| ACT-10 | `accountId` không tồn tại | Lỗi 110000. ⚠ `404` (message `Invalid account ID.` khớp luật "Invalid → 404") hay `409` (theo dải) | ○ | [ ] |
