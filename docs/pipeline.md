# Pipeline — Luồng xử lý & quy trình phát triển

> **Loại tài liệu:** gồm 2 loại "pipeline" người ta hay nói tới:
> 1. **Runtime pipeline**: một request / một nghiệp vụ chạy qua hệ thống thế nào (§1–§2).
> 2. **Delivery pipeline (CI/CD)**: code đi từ máy bạn tới bản chạy được thế nào (§3–§4).
>
> Kiến trúc tầng: [`system_design.md`](system_design.md) §3. Quy tắc nghiệp vụ: [`SRS/01_SRS.md`](SRS/01_SRS.md) §5.

## Mục lục

- [1. Request pipeline](#1-request-pipeline)
- [2. Luồng nghiệp vụ chính](#2-luồng-nghiệp-vụ-chính)
- [3. Quy trình phát triển](#3-quy-trình-phát-triển)
- [4. CI/CD pipeline](#4-cicd-pipeline)

---

## 1. Request pipeline

Thứ tự middleware trong `Program.cs` quyết định request bị chặn ở đâu. Thứ tự sai là lỗi bảo mật.

```mermaid
flowchart TB
    In([HTTP request]) --> EH[1. Exception handler<br/>bọc mọi lỗi thành envelope JSON]
    EH --> CORS[2. CORS<br/>chỉ cho phép origin của frontend]
    CORS --> AuthN[3. Authentication<br/>đọc JWT, kiểm tra trạng thái tài khoản]
    AuthN --> AuthZ[4. Authorization<br/>kiểm tra vai trò theo Authorize]
    AuthZ --> Route[5. Routing → Controller]
    Route --> Val{6. Input hợp lệ?}
    Val -- không --> E400[400 + envelope]
    Val -- có --> Svc[7. Service<br/>quyền sở hữu, điều phối]
    Svc --> Repo[8. Repository → Data → proc]
    Repo --> Ok[9. 200/201 + envelope]
    Repo -- proc THROW --> EH
```

| Bước | Thất bại thì trả |
|---|---|
| 3. Không có token / token sai / tài khoản bị khoá | `401` |
| 4. Sai vai trò | `403` |
| 6. Input sai định dạng | `400` |
| 7. Tài nguyên không thuộc người dùng | `403` |
| 8. Vi phạm quy tắc nghiệp vụ (proc `THROW`) | `404` / `409` / `422` theo [`api_contract.md`](api_contract.md) §2 |
| Lỗi không lường trước | `500` |

---

## 2. Luồng nghiệp vụ chính

### 2.1 Đăng ký & kích hoạt (UC-01)

```mermaid
sequenceDiagram
    actor G as Guest
    participant API
    participant DB as SQL Server
    G->>API: POST /auth/register (username, email, phone, password)
    API->>API: hash mật khẩu
    API->>DB: sp_account_register(hash)
    DB-->>API: tài khoản Pending
    G->>API: POST /auth/otp (purpose = Register)
    API->>DB: sp_otp_generate_otpcode
    DB-->>API: otp_code
    API->>API: ghi log / gửi email (KHÔNG trả về client)
    API-->>G: otpId, expiresAt
    G->>API: POST /auth/otp/verify (otpCode)
    API->>DB: sp_otp_verify
    G->>API: POST /auth/activate
    API->>DB: sp_account_activate
    DB-->>API: tài khoản Active
```

### 2.2 Đăng nhập (UC-02)

```mermaid
sequenceDiagram
    actor G as Guest
    participant API
    participant DB as SQL Server
    G->>API: POST /auth/login (username, password)
    API->>DB: sp_account_get_credentials
    DB-->>API: hash + trạng thái
    API->>API: so khớp hash
    alt đúng mật khẩu và Active
        API->>DB: sp_login_history_create (Successful, IP, device)
        API-->>G: 200 + JWT
    else sai hoặc không Active
        API->>DB: sp_login_history_create (Failed, IP, device)
        API-->>G: 401
    end
```

### 2.3 Chuyển khoản (UC-11)

```mermaid
sequenceDiagram
    actor C as Customer
    participant TX as TransactionService
    participant ACC as IAccountService
    participant DB as SQL Server
    participant N as INotificationService
    C->>TX: POST /transactions/transfer
    TX->>ACC: tài khoản nguồn có thuộc C?
    ACC-->>TX: có / không (không → 403)
    TX->>DB: sp_bank_transaction_transfer
    Note over DB: một giao dịch SQL:<br/>trừ nguồn có điều kiện (guarded update)<br/>cộng đích, ghi BankTransaction
    DB-->>TX: giao dịch Successful (hoặc THROW 250040 thiếu số dư)
    TX-)N: gửi thông báo (lỗi thì chỉ log)
    TX-->>C: 200 + chi tiết giao dịch
```

### 2.4 Vòng đời trạng thái

**Tài khoản đăng nhập**
```mermaid
stateDiagram-v2
    [*] --> Pending: đăng ký
    Pending --> Active: xác thực OTP
    Active --> Locked: Admin khoá
    Locked --> Active: Admin mở khoá
    Active --> Disabled: Admin vô hiệu hoá
    Disabled --> Active: Admin bật lại
```

**Tài khoản ngân hàng**
```mermaid
stateDiagram-v2
    [*] --> Active: mở tài khoản
    Active --> Frozen: nhân viên đóng băng
    Frozen --> Active: mở băng
    Active --> Closed: đóng tài khoản
    Closed --> [*]
```

**Khoản vay**
```mermaid
stateDiagram-v2
    [*] --> Pending: khách hàng đăng ký
    Pending --> Approved: Loan Officer duyệt
    Pending --> Rejected: Loan Officer từ chối
    Approved --> Disbursed: giải ngân
    Disbursed --> Disbursed: trả một kỳ
    Disbursed --> Closed: trả hết dư nợ
    Rejected --> [*]
    Closed --> [*]
```

**Sổ tiết kiệm**
```mermaid
stateDiagram-v2
    [*] --> Active: mở sổ
    Active --> Matured: job đáo hạn hằng ngày
    Active --> Closed: tất toán trước hạn (chỉ nhận gốc)
    Matured --> Closed: tất toán (gốc + lãi)
    Closed --> [*]
```

**Thẻ**
```mermaid
stateDiagram-v2
    [*] --> Active: phát hành
    Active --> Blocked: khoá thẻ
    Blocked --> Active: mở khoá
    Active --> Expired: hết hạn
```

> Các chuyển trạng thái do proc kiểm soát. Sơ đồ mô tả hành vi mong đợi để viết test. Nếu proc cho phép khác đi, sửa sơ đồ theo proc.

---

## 3. Quy trình phát triển

### 3.1 Vòng làm một task

```mermaid
flowchart LR
    A[Chọn task kế tiếp<br/>trong PLAN.md] --> B[Đọc use case + proc liên quan]
    B --> C[Viết test theo tiêu chí nghiệm thu<br/>→ chạy, thấy fail]
    C --> D[Cài đặt Repository → Service → Controller]
    D --> E[deploy.ps1 -Seed<br/>+ dotnet test]
    E -- fail --> D
    E -- pass --> F[Tự review theo Definition of Done]
    F --> G[Commit]
```

### 3.2 Definition of Done

Một task chỉ coi là xong khi đủ các điều sau:

- [ ] Mọi tiêu chí nghiệm thu trong `PLAN.md` có test và test xanh.
- [ ] `dotnet build` không cảnh báo mới; `dotnet test` xanh trên DB vừa dựng lại bằng `deploy.ps1 -Seed`.
- [ ] Response đúng [`api_contract.md`](api_contract.md): envelope, tiền là chuỗi, ngày không offset, enum đúng chuỗi gốc.
- [ ] Không lộ `password_hash`, `otp_code`, số thẻ đầy đủ (trừ lúc phát hành thẻ).
- [ ] Endpoint có id tài nguyên của khách hàng đã kiểm tra quyền sở hữu.
- [ ] Đã cập nhật tài liệu nếu hành vi khác với tài liệu.

### 3.3 Quy ước git

| Mục | Quy ước |
|---|---|
| Nhánh | `master` luôn chạy được; mỗi task một nhánh `feature/<tên-task>` khi muốn thử nghiệm dài |
| Commit message | Conventional Commits: `feat(accounts): open banking account`, `fix(auth): log failed login`, `docs: update SRS`, `test(transactions): concurrent transfer` |
| Kích thước commit | Mỗi commit một ý, build được |

---

## 4. CI/CD pipeline

> Trạng thái: **chưa có**. Dựng ở milestone M5 trong `PLAN.md`. Dưới đây là thiết kế.

```mermaid
flowchart LR
    Push([push / pull request]) --> Restore[dotnet restore]
    Restore --> Build[dotnet build<br/>-warnaserror]
    Build --> DB[Khởi động SQL Server<br/>service container]
    DB --> Deploy[deploy.ps1 -Docker -Seed<br/>DEPLOY OK + SEED OK]
    Deploy --> Test[dotnet test]
    Test --> Image[docker build<br/>BankingSystem.Api]
    Image --> Done([✔ sẵn sàng merge])
```

| Stage | Mục đích | Fail khi |
|---|---|---|
| Build | Code biên dịch được | Lỗi biên dịch hoặc cảnh báo |
| Deploy DB | Schema + proc dựng được từ đầu (bắt lỗi deferred name resolution) | `deploy.ps1` không in `DEPLOY OK` / `SEED OK` |
| Test | Hành vi đúng trên DB thật | Có test đỏ |
| Docker image | Đóng gói được | `docker build` lỗi |

Công cụ dự kiến: GitHub Actions, workflow `.github/workflows/ci.yml`. Chưa có bước tự động triển khai lên server (CD), vì đây là đồ án chạy local.
