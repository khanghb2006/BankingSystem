# Banking System

API ngân hàng số cho ba nhóm người dùng: **khách hàng** (mở tài khoản, chuyển tiền, vay, gửi tiết kiệm), **nhân viên** (giao dịch tại quầy, duyệt khoản vay) và **quản trị viên** (nhân sự, chi nhánh, khoá tài khoản, thống kê).

> Trạng thái: database hoàn chỉnh (63 stored procedure); API đang xây lại theo [`PLAN.md`](PLAN.md).

## Công nghệ

| Thành phần | Công nghệ |
|---|---|
| API | ASP.NET Core Web API (C#, .NET 10) |
| Database | SQL Server, nghiệp vụ trong stored procedure |
| Xác thực | JWT + OTP |
| Kiểm thử | xUnit, integration test trên DB thật |
| Đóng gói | Docker Compose |

## Cấu trúc

```
BankingSystem/
├── BankingSystem.Api/      API: Features/ (theo nghiệp vụ), Domain/, Data/, Common/
├── BankingSystem.Tests/    test
├── database/               schema, stored procedure, seed, deploy.ps1
├── docs/                   SRS, system design, pipeline, API contract
├── AGENTS.md               quy tắc cho AI agent
└── PLAN.md                 lộ trình triển khai
```

Giải thích chi tiết: [`docs/system_design.md`](docs/system_design.md) §4.

## Chạy trên máy

Yêu cầu: .NET SDK 10, SQL Server (Express) instance `SQLEXPRESS01`, PowerShell 7, `sqlcmd`.

```bash
pwsh -File database/deploy.ps1 -Seed
```

```bash
dotnet test
```

```bash
dotnet run --project BankingSystem.Api
```

Mở `/swagger` trên cổng in ra trong console.

Dùng Docker thay cho SQL Server cài sẵn:

```bash
docker compose up -d
```

```bash
pwsh -File database/deploy.ps1 -Docker -Seed
```

## Tài liệu

Bắt đầu từ [`docs/README.md`](docs/README.md).

## Tác giả

Huynh Bao Khang
