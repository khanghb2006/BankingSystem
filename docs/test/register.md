# Test: `POST /api/auth/register`

Liên quan: [`README.md`](README.md) (ký hiệu, quy ước chung) · proc `dbo.sp_account_register` · DTO `RegisterRequestDto`.

**Luật của DTO** (kiểm trước khi chạm DB): username `^[A-Za-z0-9_.]{3,50}\z` · email đúng định dạng, tối đa 100 ký tự · số điện thoại `^[0-9]{9,20}\z` · mật khẩu 8–128 ký tự · cả bốn field bắt buộc.

**Mã lỗi của proc:** 140000 username trùng · 140010 email trùng · 140020 số điện thoại trùng · 140030 tạo thất bại. Tất cả → `409`, domain `account`. Proc kiểm theo đúng thứ tự username, email, số điện thoại.

## 1. Thành công

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| REG-01 | Đăng ký với dữ liệu hợp lệ | `200`, `success: true`, `data.status = "Pending"`, `data.role = "Customer"`, `data.accountId` là số | ★ | [ ] |
| REG-02 | Sau REG-01, đọc `password_hash` trong DB | Khác mật khẩu gốc; `PasswordHasher.VerifyHashedPassword(hash, mật khẩu gốc)` trả thành công | ★ | [ ] |
| REG-03 | Soi toàn bộ body response của REG-01 | Không chứa mật khẩu gốc; không có key nào có chữ `password` hay `hash` | ★ | [ ] |
| REG-04 | Hai tài khoản dùng cùng một mật khẩu | Hai `password_hash` trong DB khác nhau (salt ngẫu nhiên) | ○ | [ ] |
| REG-19 | `createdAt` trong response | Dạng `yyyy-MM-ddTHH:mm:ss`, không có offset; `updatedAt` là `null` | ○ | [ ] |

## 2. Trùng dữ liệu → `409`

Mỗi ca đăng ký một tài khoản "gốc" trước, rồi đăng ký lại.

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| REG-05 | Trùng username, email và số điện thoại khác | `409`, `error.code = 140000`, `error.domain = "account"` | ★ | [ ] |
| REG-06 | Trùng email, username và số điện thoại khác | `409`, `error.code = 140010` | ★ | [ ] |
| REG-07 | Trùng số điện thoại, username và email khác | `409`, `error.code = 140020` | ★ | [ ] |
| REG-08 | Trùng username khác hoa thường (`alice` rồi `ALICE`) | `409`, `140000` nếu collation của DB không phân biệt hoa thường. Xác nhận bằng cách chạy | ○ | [ ] |
| REG-18 | Hai request cùng username chạy song song | Một `200`, một `409`. **Có thể lộ lỗi:** nếu lỗi UNIQUE của SQL Server (mã nhỏ hơn 50000) lọt ra thì kết quả là `500` | ◇ | [ ] |

## 3. Dữ liệu sai → `400` (không chạm DB)

Mọi ca: `400`, `success: false`, `error.code = 400`, `error.domain = "validation"`.

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| REG-10 | Thiếu lần lượt từng field: username, email, phoneNumber, password | `400` cho cả 4 (nên viết dạng một test nhiều dữ liệu) | ★ | [ ] |
| REG-11 | Mật khẩu 7 ký tự và 129 ký tự | `400` | ★ | [ ] |
| REG-11b | Mật khẩu đúng 8 ký tự và đúng 128 ký tự (kiểm biên) | `200` | ★ | [ ] |
| REG-12 | Username lạ: có khoảng trắng; có dấu nháy đơn; `bob` kèm xuống dòng cuối; 2 ký tự; 51 ký tự; có chữ có dấu (`é`) | `400` cho tất cả | ★ | [ ] |
| REG-13 | Số điện thoại: có chữ; 8 chữ số; 21 chữ số | `400` | ○ | [ ] |
| REG-14 | Email: sai định dạng; dài hơn 100 ký tự | `400` | ○ | [ ] |
| REG-15 | Body rỗng; JSON hỏng | `400` đúng envelope, không phải `500` | ○ | [ ] |

## 4. Bảo mật

| Mã | Tình huống | Kỳ vọng | Mức | Test |
|---|---|---|---|---|
| REG-09 | Body có thêm `"role": "Admin"` và `"status": "Active"` | `200` nhưng tài khoản vẫn `role = "Customer"`, `status = "Pending"` (chống over-posting) | ★ | [ ] |
| REG-16 | Gửi mật khẩu 7 ký tự có giá trị dễ nhận ra (ví dụ `Zq7!xk9`) để bị `400` | `message` của `400` chỉ liệt kê tên field; **không chứa** chuỗi `Zq7!xk9` | ★ | [ ] |
| REG-17 | Email chứa dấu nháy đơn (`o'neil@example.com`) | Không bao giờ `500`. Hoặc `200` và lưu nguyên văn, hoặc `400`. Cả hai chấp nhận được; mục đích là chứng minh tham số hoá chống injection | ○ | [ ] |
