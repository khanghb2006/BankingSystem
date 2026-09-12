# backend/Plan.md — Hướng dẫn dựng ASP.NET Core Web API

> **File này khác `PLAN.md` ở gốc repo.**
> - `../PLAN.md` = **hợp đồng / spec**: định dạng ID–tiền–enum–ngày–lỗi (§1), danh sách endpoint đầy đủ (Phụ lục A), bảng mã lỗi (Phụ lục B). Là **nguồn sự thật**, không chép lại vào đây.
> - `backend/Plan.md` (file này) = **cầm tay chỉ việc**: tạo project, cây thư mục, từng file làm gì, viết theo thứ tự nào, chạy & test ra sao.
>
> ⚠️ **2026-09-12: đổi từ Spring Boot (Java) sang ASP.NET Core (C#).** `../PLAN.md` §3 vẫn còn nhắc "Spring/Java" ở vài chỗ — đó là tài liệu cũ chưa cập nhật theo stack mới, cứ đọc như đang nói về ASP.NET Core (kiến trúc — proc là nguồn sự thật, thin service, không ORM — giữ nguyên, chỉ đổi ngôn ngữ/framework). Không có code C# nào tồn tại trước đây trong repo này — bắt đầu từ đầu.
>
> Trước khi code: đọc `../PLAN.md` §1 (contract), §3 (backend — bỏ qua chi tiết Java, giữ nguyên tắc), Phụ lục A + B. Roadmap tổng ở `../PLAN.md` §5 — file này chi tiết hoá **Phase 2** (skeleton + 1 lát cắt dọc `sp_branch_create`).

---

## Mục lục

- [0. Nguyên tắc kiến trúc (đọc 1 lần)](#0-nguyên-tắc-kiến-trúc-đọc-1-lần)
  - [0.1 Vì sao ASP.NET Core, không ORM](#01-vì-sao-aspnet-core-không-orm)
- [1. Chuẩn bị máy](#1-chuẩn-bị-máy)
- [2. Tạo project + gói NuGet](#2-tạo-project--gói-nuget)
- [3. Cây thư mục đầy đủ](#3-cây-thư-mục-đầy-đủ)
- [4. `appsettings.json` + kết nối DB](#4-appsettingsjson--kết-nối-db)
- [5. Giải thích từng component](#5-giải-thích-từng-component)
  - [5.1 `Program.cs`](#51-programcs)
  - [5.2 `Db/` — nói chuyện với stored procedure](#52-db--nói-chuyện-với-stored-procedure)
  - [5.3 `Common/` — envelope + xử lý lỗi](#53-common--envelope--xử-lý-lỗi)
  - [5.4 JSON, CORS, Swagger](#54-json-cors-swagger)
  - [5.5 `Security/` — JWT + phân quyền (Phase 3)](#55-security--jwt--phân-quyền-phase-3)
  - [5.6 Một feature = Controller + Service + Dto](#56-một-feature--controller--service--dto)
  - [5.7 `Loan/AmortizationSchedule` + `Saving/MaturedSavingsJob`](#57-loanamortizationschedule--savingmaturedsavingsjob)
- [6. Thứ tự viết code cho Phase 2](#6-thứ-tự-viết-code-cho-phase-2)
- [7. Chạy & test](#7-chạy--test)
- [8. Bảng tra: kiểu DB → C# → JSON](#8-bảng-tra-kiểu-db--c--json)
- [9. Checklist "Phase 2 xong"](#9-checklist-phase-2-xong)
- [10. Sau Phase 2](#10-sau-phase-2)

---

## 0. Nguyên tắc kiến trúc (đọc 1 lần)

| Nguyên tắc | Nghĩa là |
|---|---|
| **Proc là nguồn sự thật** | Mọi thao tác ghi đi qua `dbo.sp_*`. ASP.NET Core **không** tự viết SQL số dư, không EF Core, không `DbContext`, không entity. |
| **Service mỏng** | Mỗi service method = `validate input` → `sp.CallAsync("sp_xxx", ...)` → `map result` → `ApiResponse`. Thường 3–8 dòng. |
| **1 request = 1 proc call** | Không `TransactionScope` ở app — proc tự `BEGIN/COMMIT/ROLLBACK`. |
| **Chỉ 1 chỗ chạm ADO.NET** | `StoredProcedureExecutor`. Không class nào khác `using Microsoft.Data.SqlClient`. |
| **Feature-based packaging** | Gom theo nghiệp vụ (`Branch/`, `Loan/`…), không theo tầng (`Controllers/`, `Services/`). Sửa 1 tính năng chỉ mở 1 folder. |
| **C# tự tính đúng 1 thứ** | Lịch trả góp (`AmortizationSchedule`). Còn lại proc lo hết. |
| **Không viết sẵn 60 controller** | Có 2 mẫu (Branch = CRUD, Transfer = có ownership). Nhân bản theo Phụ lục A khi tới phase tương ứng. |

Vì sao mỏng vậy: DB đã có 63 proc + 54 function validate + guarded-UPDATE chống đua. Viết lại quy tắc trong C# = 2 bản phải đồng bộ tay. ASP.NET Core chỉ làm phần DB **không** làm được: HTTP/JSON, hash mật khẩu, JWT, phân trang, đọc IP request, job nền định kỳ.

### 0.1 Vì sao ASP.NET Core, không ORM

Mặc định `dotnet new webapi` không kéo theo EF Core — chọn đúng, **đừng** thêm `Microsoft.EntityFrameworkCore.SqlServer`. Lý do giống hệt bản Java cũ: proc đã ép hết invariant + state machine, thêm `DbContext`/entity là một bản sao thứ 2 của quy tắc phải đồng bộ tay.

Gọi proc bằng ADO.NET thuần (`Microsoft.Data.SqlClient`) qua `SqlCommand` + `CommandType.StoredProcedure`. Khác một chỗ quan trọng so với JDBC: **ADO.NET bind theo TÊN tham số, không theo vị trí.** JDBC `{call sp(?, ?, ?)}` positional rất dễ gõ sai thứ tự; ADO.NET buộc bạn khai `("@branch_name", value)` — chậm gõ hơn vài ký tự nhưng **an toàn hơn**, không còn phải mở file `.sql` đối chiếu thứ tự tham số như bản Java. Xem `StoredProcedureExecutor` ở §5.2.

**Bỏ qua có chủ đích:** EF Core / Dapper (không ORM, giống lý do trên), AutoMapper (mapper viết tay theo view — §5.6 — 5-7 dòng, thư viện chỉ thêm phép màu khó debug), FluentValidation (DataAnnotations built-in đã đủ cho input đơn giản của đồ án).

---

## 1. Chuẩn bị máy

| Cần | Kiểm tra |
|---|---|
| .NET SDK (LTS mới nhất — 8 hoặc 10 tuỳ bản đang hỗ trợ khi cài) | `dotnet --version` |
| Visual Studio 2022+ hoặc Rider hoặc VS Code + C# Dev Kit | — |
| SQL Server đang chạy + đã deploy `BankingSystem` | xem dưới |

**DB cho backend dev — dùng Docker cho nhẹ đầu:**

```bash
docker compose up -d
pwsh -File database/deploy.ps1 -Docker -Seed
```

→ SQL Server ở `localhost:1433`, user `sa`, password `BankSys_2026!` (trong `docker-compose.yml`), có sẵn demo data (1 branch, 2 customer…).

> Vì sao không dùng `localhost\SQLEXPRESS01` như `deploy.ps1` mặc định: named instance cần dịch vụ SQL Server Browser bật + Windows auth hoặc 1 login SQL riêng — lằng nhằng hơn Docker (SQL auth, cắm phát chạy).

---

## 2. Tạo project + gói NuGet

```bash
cd backend
dotnet new webapi -n Backend --use-controllers -o .
```

`--use-controllers`: dùng `[ApiController]` + class Controller thay vì Minimal API — khớp cấu trúc "1 feature = 1 Controller class" ở §5.6, dễ đọc hơn khi có 13 module.

Thêm gói (chỉ những gì thật sự cần, không thêm "cho chắc"):

```bash
dotnet add package Microsoft.Data.SqlClient
dotnet add package Swashbuckle.AspNetCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer   # Phase 3, thêm khi tới lúc dùng
dotnet add package Microsoft.AspNetCore.Identity                  # Phase 3, chỉ để lấy PasswordHasher<T> (PBKDF2) — khỏi cần BCrypt.Net ngoài
```

**Không cần thêm** cho Phase 2: JSON dùng `System.Text.Json` có sẵn trong SDK, validate dùng `System.ComponentModel.DataAnnotations` có sẵn, test dùng `Microsoft.AspNetCore.Mvc.Testing` (`dotnet new webapi` không kéo sẵn, thêm khi tới bước viết test ở §6 bước 10).

---

## 3. Cây thư mục đầy đủ

Namespace gốc `Backend`. `(P3)` = làm ở Phase 3, `(P7)`… = phase sau. Không có nhãn = Phase 2.

```
backend/
├── Backend.csproj
├── Program.cs                             ← thay cho Startup.cs kiểu cũ; đăng ký DI + middleware pipeline
├── appsettings.json                       ← config chung (commit được)
├── appsettings.Development.json           ← password thật — .gitignore, KHÔNG commit
├── Plan.md
└── (Controllers/ mặc định do template sinh — XOÁ, dùng feature-based bên dưới)
├── Db/
│   ├── StoredProcedureExecutor.cs         CHỖ DUY NHẤT gọi `dbo.sp_*`
│   └── Rows.cs                            SqlDataReader → List<Dictionary>; trim NCHAR, ép tiền/ngày
│
├── Common/
│   ├── ApiResponse.cs                     envelope {success,message,data,error}
│   ├── ApiError.cs                        {code, domain}
│   ├── SqlErrorCatalog.cs                 mã THROW → (domain, HTTP status)
│   ├── ApiExceptionHandler.cs             IExceptionHandler — bắt SqlException → envelope
│   └── PagedResponse.cs                   cắt trang trong bộ nhớ (§1.9)
│
├── Security/                              (P3 — Phase 2 chưa cần: không đăng ký Authentication)
│   ├── JwtOptions.cs                      record bind từ appsettings app:jwt
│   ├── JwtIssuer.cs                       phát token khi login OK
│   └── OwnershipGuard.cs                  "TK này có phải của người đăng nhập?"
│
├── Branch/                                ★ MẪU 1 — CRUD thuần
│   ├── BranchController.cs
│   ├── BranchService.cs
│   └── Dto/
│       ├── CreateBranchRequest.cs
│       ├── UpdateBranchRequest.cs
│       └── BranchResponse.cs
│
├── Auth/            (P3)  register→otp→activate→login, /me, đổi/quên mật khẩu
├── Customer/        (P4)
├── Employee/        (P4)
├── BankingAccount/  (P5)
├── Card/            (P5)
├── Transaction/     (P6)  ★ MẪU 2 — có OwnershipGuard, phần đồng thời trọng yếu
├── Loan/            (P7)  + AmortizationSchedule.cs  (C# tự tính)
├── Saving/          (P8)  + MaturedSavingsJob.cs      (BackgroundService, không thư viện ngoài)
├── Beneficiary/     (P9)
├── Notification/    (P9)
├── LoginHistory/    (P3)
└── Admin/           (P10)

test/
└── Backend.Tests/
    ├── Backend.Tests.csproj
    ├── BranchApiTests.cs                  integration test lát cắt dọc
    └── Loan/AmortizationScheduleTests.cs  (P7) Σ principal == principal, dư nợ cuối == 0
```

**Quy ước đặt tên trong 1 feature folder** (giống hệt nhau cho cả 13 module):

| File | Vai trò | Chứa gì |
|---|---|---|
| `XxxController.cs` | Nhận HTTP, không có logic | `[ApiController]`, `[Route("api/xxx")]`, mỗi method map 1 endpoint Phụ lục A, gọi thẳng service, trả `ApiResponse<T>` |
| `XxxService.cs` | Điều phối | Gọi `OwnershipGuard` (nếu cần) → `sp.CallAsync(...)` → `Map(row)` → `ApiResponse.Ok/…` |
| `Dto/CreateXxxRequest.cs` | Input | `record` + DataAnnotations (`[Required]`, `[Range]`…). Field **PascalCase** trong C#, JSON tự đổi camelCase (§5.4). |
| `Dto/XxxResponse.cs` | Output | `record` mirror đúng cột của `vw_Xxx` tương ứng. |

---

## 4. `appsettings.json` + kết nối DB

`appsettings.json` (commit được, không có password thật):

```json
{
  "Logging": {
    "LogLevel": { "Default": "Information", "Microsoft.AspNetCore": "Warning" }
  },
  "AllowedHosts": "*",
  "Cors": { "AllowedOrigin": "http://localhost:5173" },
  "Jwt": {
    "TtlMinutes": 60
  }
}
```

`appsettings.Development.json` (thêm `.gitignore`, chứa password thật):

```json
{
  "ConnectionStrings": {
    "BankingSystem": "Server=localhost,1433;Database=BankingSystem;User Id=sa;Password=BankSys_2026!;TrustServerCertificate=True;Encrypt=False"
  },
  "Jwt": { "Secret": "dev-only-secret-please-change-min-32-bytes-long" }
}
```

> **Thay thế khác nếu không muốn thêm file:** `dotnet user-secrets init` rồi `dotnet user-secrets set "ConnectionStrings:BankingSystem" "..."` — Secret Manager là tính năng có sẵn của SDK, không lưu trong repo, không cần nhớ thêm 1 file vào `.gitignore`. Chọn 1 trong 2 cách, không cần cả hai.

**`TrustServerCertificate=True;Encrypt=False`** bắt buộc khi test local: driver mặc định `Encrypt=True` (bắt buộc từ các bản driver mới), gặp self-signed cert của SQL Server local sẽ ném lỗi handshake.

> **Không có khái niệm "timezone mặc định của app" như JVM.** `DateTime` đọc từ cột `DATETIME` qua ADO.NET có `Kind = Unspecified` — cứ để nguyên, **đừng** gọi `.ToLocalTime()`/`.ToUniversalTime()` ở đâu cả, serialize thẳng ra JSON không offset (§1.4, §8). SQL Server và máy dev cùng hiểu là giờ `Asia/Ho_Chi_Minh` theo quy ước, không cần ép ở tầng C#.

> **Named instance** (nếu không dùng Docker): `Server=localhost\SQLEXPRESS01;Database=BankingSystem;...` — cần dịch vụ **SQL Server Browser** đang chạy.

---

## 5. Giải thích từng component

### 5.1 `Program.cs`

`dotnet new webapi` sinh sẵn file này với top-level statements (không có `Startup.cs` — cách làm chuẩn từ .NET 6 trở đi, mọi tutorial cũ dùng `Startup.cs` đã lỗi thời). Đăng ký DI + middleware pipeline ở đây, Phase 2:

```csharp
using System.Text.Json;
using Backend.Common;
using Backend.Db;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers().AddJsonOptions(o =>
{
    o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    o.JsonSerializerOptions.Converters.Add(new DecimalAsStringConverter());
    o.JsonSerializerOptions.Converters.Add(new DateTimeNoOffsetConverter());
});

builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(o =>
{
    o.InvalidModelStateResponseFactory = ctx =>
    {
        var msg = string.Join("; ", ctx.ModelState
            .Where(e => e.Value?.Errors.Count > 0)
            .Select(e => $"{e.Key}: {e.Value!.Errors[0].ErrorMessage}"));
        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(
            ApiResponse<object>.Fail(msg, new ApiError(400, "validation")));
    };
});

builder.Services.AddScoped<StoredProcedureExecutor>();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .WithOrigins(builder.Configuration["Cors:AllowedOrigin"]!)
    .WithMethods("GET", "POST", "PUT", "DELETE")
    .WithExposedHeaders("X-Total-Count")));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler(_ => { });   // đăng ký ApiExceptionHandler ở trên
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();
app.MapControllers();

app.Run();

public partial class Program { }   // để WebApplicationFactory<Program> ở test (§6 bước 10) thấy được entry point
```

- `AddControllers()` quét mọi class kế thừa `ControllerBase` trong assembly — tương đương `@ComponentScan`, không cần khai báo thủ công.
- Dòng `public partial class Program { }` là gotcha quen thuộc với top-level statements: thiếu nó thì `WebApplicationFactory<Program>` ở integration test không compile được.

### 5.2 `Db/` — nói chuyện với stored procedure

**`Rows.cs`** — chuyển `SqlDataReader` sang `List<Dictionary>` và ép kiểu đúng contract §1:

```csharp
namespace Backend.Db;

using Microsoft.Data.SqlClient;

public static class Rows
{
    public static async Task<List<Dictionary<string, object?>>> ToMapsAsync(SqlDataReader reader)
    {
        var result = new List<Dictionary<string, object?>>();
        while (await reader.ReadAsync())
        {
            var row = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < reader.FieldCount; i++)
                row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            result.Add(row);
        }
        return result;
    }

    // NCHAR(10) pad khoảng trắng → luôn .Trim() (§1.1)
    public static string? Str(Dictionary<string, object?> m, string key)
        => m.GetValueOrDefault(key)?.ToString()?.Trim();

    public static long? Lng(Dictionary<string, object?> m, string key)
        => m.GetValueOrDefault(key) is { } v ? Convert.ToInt64(v) : null;

    public static decimal? Money(Dictionary<string, object?> m, string key)          // §1.2
        => m.GetValueOrDefault(key) is { } v ? Math.Round(Convert.ToDecimal(v), 2, MidpointRounding.AwayFromZero) : null;

    public static DateTime? Dt(Dictionary<string, object?> m, string key)            // DATETIME (§1.4)
        => m.GetValueOrDefault(key) as DateTime?;

    public static DateOnly? Date(Dictionary<string, object?> m, string key)          // DATE
        => m.GetValueOrDefault(key) is DateTime v ? DateOnly.FromDateTime(v) : null;
}
```

**`StoredProcedureExecutor.cs`** — điểm tiếp xúc DUY NHẤT với `sp_*`:

```csharp
namespace Backend.Db;

using System.Data;
using Microsoft.Data.SqlClient;

public sealed class StoredProcedureExecutor(IConfiguration config)
{
    private readonly string _connectionString = config.GetConnectionString("BankingSystem")
        ?? throw new InvalidOperationException("Missing ConnectionStrings:BankingSystem");

    /// Gọi dbo.<proc> với tham số CÓ TÊN (phải khớp tên khai báo trong file .sql); trả các dòng của result set đầu tiên.
    public async Task<List<Dictionary<string, object?>>> CallAsync(string proc, params (string Name, object? Value)[] args)
    {
        await using var conn = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand($"dbo.{proc}", conn) { CommandType = CommandType.StoredProcedure };
        foreach (var (name, value) in args)
            cmd.Parameters.AddWithValue(name, value ?? DBNull.Value);

        await conn.OpenAsync();
        await using var reader = await cmd.ExecuteReaderAsync();
        return await Rows.ToMapsAsync(reader);
    }

    /// Dòng đầu; ném nếu proc không trả gì (proc thành công LUÔN SELECT ... 'message').
    public async Task<Dictionary<string, object?>> OneAsync(string proc, params (string, object?)[] args)
    {
        var rows = await CallAsync(proc, args);
        if (rows.Count == 0) throw new InvalidOperationException($"{proc} trả về 0 dòng");
        return rows[0];
    }

    public string? Message(Dictionary<string, object?> row)
        => (row.GetValueOrDefault("message") ?? row.GetValueOrDefault("result_message"))?.ToString();
}
```

Vì sao tham số **có tên** chứ không vị trí như bản JDBC cũ: ADO.NET gửi RPC theo tên tham số cho SQL Server, sai tên là proc báo lỗi "expects parameter which was not supplied" ngay lập tức — thực ra **an toàn hơn** bản positional, lỗi lộ ra sớm thay vì âm thầm gán nhầm cột.

Vì sao dùng `SqlDataReader` thô chứ không Dapper: proc trả **result set** kèm cột `message` ở cuối, không map thẳng 1-1 vào 1 class được — đọc thô rồi `Rows.Str/Lng/Money/...` map tay ngắn gọn hơn học thêm 1 thư viện.

### 5.3 `Common/` — envelope + xử lý lỗi

**`ApiResponse` / `ApiError`** — mọi endpoint trả kiểu này (§1.6):

```csharp
namespace Backend.Common;

public record ApiResponse<T>(bool Success, string? Message, T? Data, ApiError? Error)
{
    public static ApiResponse<T> Ok(string? message, T? data) => new(true, message, data, null);
    public static ApiResponse<T> Fail(string? message, ApiError error) => new(false, message, default, error);
}
```
```csharp
namespace Backend.Common;
public record ApiError(int Code, string Domain);
```

**`SqlErrorCatalog`** — map số `THROW` của proc → domain + HTTP status. **Dải mã đầy đủ ở `../PLAN.md` §3.2 + Phụ lục B** — chép nguyên bảng `BANDS` từ đó. Ý tưởng:

```csharp
namespace Backend.Common;

public static class SqlErrorCatalog
{
    public record Entry(string Domain, int Status);

    public static Entry Lookup(int code)
    {
        if (code < 50000) return new Entry("system", StatusCodes.Status500InternalServerError);
        // first-match trong danh sách dải [lo, hi] → (domain, status). Xem PLAN.md §3.2.
        // mã kết thúc ...000 + message chứa "does not exist"/"Invalid" → handler override thành 404.
        return new Entry("unknown", StatusCodes.Status500InternalServerError);
    }
}
```
Có 2 hệ mã (5 chữ số cũ cho branch/card/customer/employee/loan; 6 chữ số cho phần còn lại) — catalog xử lý cả hai. Proc **mới** phải ≥ 50000 (xem memory *THROW error number range*).

**`ApiExceptionHandler`** — 1 chỗ biến exception thành envelope, dùng `IExceptionHandler` (interface có sẵn từ .NET 8, thay cho middleware tự viết tay của các bản cũ):

```csharp
namespace Backend.Common;

using Microsoft.AspNetCore.Diagnostics;
using Microsoft.Data.SqlClient;

public sealed class ApiExceptionHandler : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext ctx, Exception ex, CancellationToken ct)
    {
        if (ex is not SqlException sql) return false;   // lỗi lạ → để ProblemDetails mặc định xử lý

        var entry = SqlErrorCatalog.Lookup(sql.Number);
        var msg = CleanMessage(sql.Message);             // bỏ "... Line 42" của T-SQL
        var status = LooksLikeNotFound(msg) ? StatusCodes.Status404NotFound : entry.Status;

        ctx.Response.StatusCode = status;
        await ctx.Response.WriteAsJsonAsync(
            ApiResponse<object>.Fail(msg, new ApiError(sql.Number, entry.Domain)), cancellationToken: ct);
        return true;
    }

    private static string CleanMessage(string raw) => raw.Split('\n')[0];
    private static bool LooksLikeNotFound(string msg) =>
        msg.Contains("does not exist", StringComparison.OrdinalIgnoreCase) ||
        msg.Contains("Invalid", StringComparison.OrdinalIgnoreCase);
}
```
Nhờ handler này, service **không cần try/catch** — cứ gọi proc, lỗi tự thành JSON đúng format. Lỗi validate (`[Required]`… fail) được `InvalidModelStateResponseFactory` ở §5.1 xử lý riêng, không đi qua đây.

**`PagedResponse`** — proc `*_search` trả hết dòng; app cắt trang trong RAM (§1.9): nhận `?page=0&size=20&sort=createdAt,desc`, trả `data` = mảng trang hiện tại + header `X-Total-Count`. Chưa cần cho Phase 2.

### 5.4 JSON, CORS, Swagger

**Ép JSON theo §1.2/§1.4** bằng 2 converter nhỏ (đăng ký ở §5.1, không cần class `Config` riêng):

```csharp
namespace Backend.Common;

using System.Text.Json;
using System.Text.Json.Serialization;

public sealed class DecimalAsStringConverter : JsonConverter<decimal>
{
    public override decimal Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o) => decimal.Parse(r.GetString()!);
    public override void Write(Utf8JsonWriter w, decimal v, JsonSerializerOptions o) => w.WriteStringValue(v.ToString("F2"));
}

public sealed class DateTimeNoOffsetConverter : JsonConverter<DateTime>
{
    private const string Fmt = "yyyy-MM-dd'T'HH:mm:ss";
    public override DateTime Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o) => DateTime.Parse(r.GetString()!);
    public override void Write(Utf8JsonWriter w, DateTime v, JsonSerializerOptions o) => w.WriteStringValue(v.ToString(Fmt));
}
```

`PropertyNamingPolicy = JsonNamingPolicy.CamelCase` (§5.1) tự đổi `BranchName` (C# PascalCase) ↔ `"branchName"` (JSON) cả 2 chiều — không cần `[JsonPropertyName]` trên từng field.

**CORS** — đã đăng ký ở §5.1 (`AddCors` + `UseCors`), cho React Vite gọi khi dev.

**Swagger** — `Swashbuckle.AspNetCore` tự sinh `/swagger` (UI) từ `[ApiController]` + XML doc; không cần cấu hình thêm cho Phase 2.

### 5.5 `Security/` — JWT + phân quyền (Phase 3)

**Phase 2**: **không đăng ký gì cả** — không `AddAuthentication`, không `UseAuthorization`. Không route nào yêu cầu token, đúng theo YAGNI (Phase 2 chỉ cần test `/api/branches` chạy được).

**Phase 3** thêm (chi tiết ở `../PLAN.md` §1.10 + §3):

| Class/gói | Việc |
|---|---|
| `Microsoft.AspNetCore.Authentication.JwtBearer` | `AddAuthentication().AddJwtBearer(...)` — verify token có sẵn trong middleware, không tự viết filter. |
| `JwtIssuer` | `Issue(accountId, username, role)` khi login OK — dùng `JwtSecurityTokenHandler` (đi kèm gói JwtBearer). |
| `[Authorize]` / `ClaimsPrincipal` | Có sẵn trong ASP.NET Core — không cần tự viết class `AccountPrincipal`, đọc claim qua `User.FindFirst(...)`. |
| `OwnershipGuard` | `AssertOwnsBankAccount(user, id)` — query nhẹ qua `fn_*_validate_owner` / view; sai → ném lỗi 403 (`ForbidHttpException` tự định nghĩa hoặc trả thẳng `403` từ controller). |
| `PasswordHasher<object>` (từ `Microsoft.AspNetCore.Identity`) | Hash + verify mật khẩu (PBKDF2). Có sẵn khi thêm gói `Microsoft.AspNetCore.Identity` — khỏi cần NuGet BCrypt của bên thứ 3. |
| `Program.cs` (sửa) | Thêm `app.UseAuthentication()` trước `UseAuthorization()`; route nào cần khoá thì gắn `[Authorize]`. |

`login` **so mật khẩu ở app** (`passwordHasher.VerifyHashedPassword`), không để proc so — proc chỉ so `password_hash = @password` chuỗi thẳng.

### 5.6 Một feature = Controller + Service + Dto

**Mẫu 1 — `Branch/` (CRUD thuần).** `sp_branch_create(@branch_name, @address, @phone_number)` → `SELECT * FROM vw_Branch ... , 'Branch created successfully.' AS message`.

`Dto/CreateBranchRequest.cs`:
```csharp
namespace Backend.Branch.Dto;

using System.ComponentModel.DataAnnotations;

public record CreateBranchRequest(
    [property: Required, MaxLength(100)] string BranchName,
    [property: Required, MaxLength(100)] string Address,
    [property: Required, MaxLength(20)]  string PhoneNumber
);
```

`Dto/BranchResponse.cs` — mirror `vw_Branch` (7 cột: `branch_id, branch_name, address, phone_number, created_at, updated_at, status`):
```csharp
namespace Backend.Branch.Dto;

public record BranchResponse(
    string BranchId, string BranchName, string Address, string PhoneNumber,
    DateTime? CreatedAt, DateTime? UpdatedAt, string Status
);
```

`BranchService.cs`:
```csharp
namespace Backend.Branch;

using Backend.Branch.Dto;
using Backend.Common;
using Backend.Db;

public sealed class BranchService(StoredProcedureExecutor sp)
{
    public async Task<ApiResponse<BranchResponse>> CreateAsync(CreateBranchRequest r)
    {
        var row = await sp.OneAsync("sp_branch_create",
            ("@branch_name", r.BranchName), ("@address", r.Address), ("@phone_number", r.PhoneNumber));
        return ApiResponse<BranchResponse>.Ok(sp.Message(row), Map(row));
    }

    private static BranchResponse Map(Dictionary<string, object?> m) => new(
        Rows.Str(m, "branch_id")!, Rows.Str(m, "branch_name")!,
        Rows.Str(m, "address")!,   Rows.Str(m, "phone_number")!,
        Rows.Dt(m, "created_at"),  Rows.Dt(m, "updated_at"),
        Rows.Str(m, "status")!);
}
```

`BranchController.cs`:
```csharp
namespace Backend.Branch;

using Microsoft.AspNetCore.Mvc;
using Backend.Branch.Dto;
using Backend.Common;

[ApiController]
[Route("api/branches")]
public sealed class BranchController(BranchService service) : ControllerBase
{
    [HttpPost]
    // [Authorize(Roles = "Admin")]   // bật ở Phase 3
    public Task<ApiResponse<BranchResponse>> Create([FromBody] CreateBranchRequest req)
        => service.CreateAsync(req);
}
```

`(BranchService sp)` / `(BranchService service)` trong khai báo class là **primary constructor** (C# 12) — thay cho việc tự viết constructor gán field, ngắn hơn hẳn bản Java tương đương.

Các endpoint branch còn lại (`PUT /{id}`, `PUT /{id}/status`, `GET /{id}`, `GET /{id}/summary`, `GET ?name=&status=` — xem Phụ lục A) = copy y hệt cấu trúc trên, đổi proc + dto.

**Mẫu 2 — `Transaction/` (có ownership, Phase 6).** Khác mẫu 1 ở 2 điểm — xem `../PLAN.md` §3.3:
```csharp
[HttpPost("transfer")]
[Authorize]
public async Task<ApiResponse<TransactionResponse>> Transfer([FromBody] TransferRequest req)
{
    await ownership.AssertOwnsBankAccountAsync(User, req.FromBankAccountId);   // (1) chặn thao tác TK người khác
    var row = await sp.OneAsync("sp_bank_transaction_transfer",
        ("@from_account_id", req.FromBankAccountId), ("@to_account_id", req.ToBankAccountId),
        ("@amount", req.Amount), ("@fee", req.Fee ?? 0m), ("@description", req.Description));
    await notifier.AfterTransferAsync(row);                                   // (2) bắn Notification (Phase 9, best-effort)
    return ApiResponse<TransactionResponse>.Ok(sp.Message(row), TransactionResponse.From(row));
}
```
Phần đồng thời (20 lệnh transfer song song vượt số dư) do **guarded UPDATE trong proc** lo — app không làm gì thêm. Test kịch bản này ở `../PLAN.md` §6.

### 5.7 `Loan/AmortizationSchedule` + `Saving/MaturedSavingsJob`

**Toàn bộ** phần C# "tự làm logic". Công thức đầy đủ + test ở `../PLAN.md` §3.5 — chuyển từ pseudocode Java sang C# khi tới Phase 7/8 (cùng công thức toán, chỉ đổi cú pháp).

- **`AmortizationSchedule`** (Phase 7): lịch trả góp cho `GET /loans/{id}/schedule`. Khớp công thức `sp_loan_apply` (§1.3): `r = annual/12/100`; `M = P·r·(1+r)^n / ((1+r)^n − 1)`; `r=0` → `M = P/n`; kỳ cuối nuốt phần lẻ để dư nợ = 0. **Không** tạo bảng `LoanRepaymentSchedule` — tính runtime, YAGNI (`../PLAN.md` §2.1).
- **`MaturedSavingsJob`** (Phase 8): `BackgroundService` có sẵn trong ASP.NET Core (`Microsoft.Extensions.Hosting`, không cần thư viện scheduler ngoài như Quartz.NET) dùng `PeriodicTimer`, chạy mỗi ngày lúc 00:05 giờ VN, gọi `sp_saving_account_settle_matured`. Không tiến trình riêng.

---

## 6. Thứ tự viết code cho Phase 2

Làm đúng thứ tự này — mỗi bước có mốc "chạy được" trước khi sang bước sau:

| # | Viết | Xong khi |
|---|---|---|
| 1 | `dotnet new webapi --use-controllers` + thêm gói `Microsoft.Data.SqlClient`, `Swashbuckle.AspNetCore` (§2) + xoá `Controllers/WeatherForecast*` mẫu | `dotnet run` → log `Now listening on: http://localhost:5xxx`. Chưa có endpoint thật cũng OK. |
| 2 | `Db/Rows.cs` + `Db/StoredProcedureExecutor.cs` | `dotnet build` sạch. |
| 3 | `Common/ApiResponse.cs` + `Common/ApiError.cs` | build sạch. |
| 4 | `Common/SqlErrorCatalog.cs` (chép bảng dải từ `../PLAN.md` §3.2) + `Common/ApiExceptionHandler.cs` | build sạch. |
| 5 | `Common/DecimalAsStringConverter.cs` + `DateTimeNoOffsetConverter.cs`, đăng ký trong `Program.cs` (§5.1) | restart app, không lỗi. |
| 6 | `appsettings.Development.json` (connection string) | app kết nối được DB — thử log 1 câu ping đơn giản hoặc bỏ qua, kiểm ở bước 8. |
| 7 | `Branch/Dto/*` → `Branch/BranchService.cs` → `Branch/BranchController.cs` | restart, `/swagger` hiện `POST /api/branches`. |
| 8 | Test tay trên Swagger (§7) | body trả `{"success":true,"message":"Branch created successfully.","data":{...}}`. |
| 9 | Thử input rỗng `branchName` → nhận `400` + `error.code:400`. Thử `phoneNumber` quá 20 ký tự. | envelope lỗi đúng format. |
| 10 | Tạo `test/Backend.Tests/`, thêm gói `Microsoft.AspNetCore.Mvc.Testing` + `xunit`, viết `BranchApiTests.cs` (§7) | `dotnet test` xanh. |

Sau bước 10: Phase 2 xong. Các module khác = lặp bước 7 theo Phụ lục A.

---

## 7. Chạy & test

**Chạy:**
```bash
cd backend
dotnet run
```
Hoặc trong IDE: nhấn Run trên project `Backend`.

**Swagger UI:** `http://localhost:<port>/swagger` → `POST /api/branches` → Try it out:
```json
{ "branchName": "Chi nhánh Quận 1", "address": "12 Lê Lợi, Q1, TP.HCM", "phoneNumber": "02838220001" }
```

**Hoặc curl:**
```bash
curl -X POST http://localhost:5000/api/branches -H "Content-Type: application/json" -d "{\"branchName\":\"Chi nhánh Quận 1\",\"address\":\"12 Le Loi\",\"phoneNumber\":\"02838220001\"}"
```

**Integration test** `test/Backend.Tests/BranchApiTests.cs`:
```csharp
namespace Backend.Tests;

using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

public class BranchApiTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task Create_branch_returns_envelope()
    {
        var client = factory.CreateClient();
        var res = await client.PostAsJsonAsync("/api/branches", new
        {
            branchName = "Chi nhánh Test", address = "1 Nguyễn Huệ", phoneNumber = "02838220099"
        });
        var body = await res.Content.ReadFromJsonAsync<JsonElement>();

        Assert.True(body.GetProperty("success").GetBoolean());
        Assert.Equal("Branch created successfully.", body.GetProperty("message").GetString());
        Assert.True(body.GetProperty("data").TryGetProperty("branchId", out _));
    }
}
```

```bash
dotnet test
```

> Test này **ghi 1 dòng branch thật** vào DB dev. Chấp nhận được cho đồ án học — chạy lại `pwsh -File database/deploy.ps1 -Docker -Seed` để reset.
> `ponytail:` chưa dùng Testcontainers/DB riêng cho test — thêm ở Phase 11 (CI) khi cần DB sạch mỗi lần chạy.

---

## 8. Bảng tra: kiểu DB → C# → JSON

Chi tiết + lý do ở `../PLAN.md` §1. Tóm tắt cho lúc viết `Map(row)`:

| Cột DB | Kiểu SQL | Đọc bằng | Field C# | JSON |
|---|---|---|---|---|
| `branch_id`, `customer_id`, `employee_id` | `NCHAR(10)` | `Rows.Str` (**có Trim**) | `string` | `"BR00000001"` |
| `bank_account_id`, `transaction_id`, `loan_id`… | `BIGINT` | `Rows.Lng` | `long` | `42` (number) |
| `bank_account_number` | `NCHAR(20)` | `Rows.Str` | `string` | `"0001234500000000000"` (giữ leading zero) |
| `card_number` | `VARCHAR(20)` | `Rows.Str` | `string` | mask `"400000******1234"` — trừ response `POST /api/cards` (§1.8) |
| `balance`, `amount`, `fee`, `interest_rate` | `DECIMAL(18,2)` | `Rows.Money` | `decimal` | `"1000000.00"` (**string**, 2 số lẻ — `DecimalAsStringConverter`) |
| `created_at`, `updated_at` | `DATETIME` | `Rows.Dt` | `DateTime` | `"2026-09-09T14:30:00"` (không offset — `DateTimeNoOffsetConverter`) |
| `date_of_birth`, `maturity_date` | `DATE` | `Rows.Date` | `DateOnly` | `"2026-09-09"` (serialize mặc định đã đúng ISO, không cần converter riêng) |
| `status`, `role`, `transaction_type`… | lookup string | `Rows.Str` | `string` | đúng chuỗi gốc, kể cả `"Loan Officer"` (§1.5) |

**Không bao giờ** map ra response: `password_hash`, `cvv_hash`, `otp_code` (§1.8, §1.10).

---

## 9. Checklist "Phase 2 xong"

- [ ] `dotnet run` lên cổng, không lỗi kết nối DB.
- [ ] `/swagger` mở được, thấy `POST /api/branches`.
- [ ] `POST /api/branches` hợp lệ → `200` + `{success:true, message:"Branch created successfully.", data:{branchId:"BR…", …}}`.
- [ ] `branchName` rỗng → `400` + `{success:false, error:{code:400, domain:"validation"}}`.
- [ ] Tắt SQL Server → gọi API → `500` + envelope (không phải trang lỗi HTML mặc định).
- [ ] `dotnet test` xanh (`BranchApiTests`).
- [ ] Không class nào ngoài `Db/` `using Microsoft.Data.SqlClient`.
- [ ] `appsettings.Development.json` (hoặc user-secrets) không lộ password thật trong git.
- [ ] Commit: `backend/` skeleton + branch slice.

---

## 10. Sau Phase 2

| Phase | Thêm gì | Tài liệu |
|---|---|---|
| 3 | `Security/*` đầy đủ, `Auth/` (register→otp→activate→login→`/me`), `LoginHistory/` | `../PLAN.md` §1.10, §3, roadmap Phase 3 |
| 4 | `Customer/`, `Employee/`, phần còn lại `Branch/` | Phụ lục A |
| 5 | `BankingAccount/`, `Card/` | Phụ lục A |
| 6 | `Transaction/` (Mẫu 2) — **test đồng thời bắt buộc** | `../PLAN.md` §1.11, §6 |
| 7 | `Loan/` + `AmortizationSchedule` + test | `../PLAN.md` §3.5 |
| 8 | `Saving/` + `MaturedSavingsJob` (`BackgroundService`) | `../PLAN.md` §3.5 |
| 9 | `Beneficiary/`, `Notification/` (bắn sau transfer/loan, best-effort) | Phụ lục A |
| 10 | `Admin/` + endpoint thống kê dashboard | Phụ lục A |
| 11 | Gửi OTP email thật, rate-limit + khoá login, DB riêng cho test, CI | roadmap Phase 11 |

**Cách nhân bản:** mỗi endpoint trong Phụ lục A = 1 method controller + 1 method service + dto. Mở file `.sql` của proc để lấy **đúng tên tham số** (không phải thứ tự — §5.2), mở file `vw_*.sql` để lấy **đúng danh sách cột** cho `Response`. Không có logic mới — chỉ nối HTTP ↔ proc.
