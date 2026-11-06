# AGENTS.md — Quy tắc làm việc cho AI agent

> Dành cho mọi AI agent (Claude, Copilot, Codex…) làm việc trong repo này. Đọc hết trước khi làm bất cứ gì.
> Lộ trình việc cần làm: [`PLAN.md`](PLAN.md). Tài liệu dự án: [`docs/README.md`](docs/README.md).

---

## 1. Người dùng đang học

Người dùng **học backend C#** qua project này. Mục tiêu là họ hiểu và tự viết được, không phải agent viết cho xong.

| Quy tắc                        | Chi tiết                                                                                                                                                                                                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Không sửa code của người dùng** | Kể cả refactor hay đổi phong cách (ví dụ đổi constructor): chỉ liệt kê file cần sửa, chỉ chỗ sửa và cách sửa để người dùng tự gõ. Không dùng `git checkout` / `git restore` để hoàn tác vì sẽ mất thay đổi chưa commit của họ. |
| **Không tự commit** | Agent không chạy `git add`, `git commit`, `git push`, `git reset`, `git rebase`. Khi xong một bước chỉ gợi ý lệnh commit (kèm message) trong chat để người dùng tự gõ. |
| **Không tự ghi code vào file** | Code mới (C#, SQL) phải **hiện trong chat**, người dùng tự gõ vào file. Agent chỉ ghi trực tiếp khi người dùng yêu cầu rõ ràng cho lần đó. Tài liệu (`.md`) thì được ghi khi được yêu cầu.                                                                   |
| **Giải thích trước, code sau** | Mỗi đoạn code đi kèm phải clean và abstract: nó làm gì, vì sao viết vậy, thuộc task nào trong `PLAN.md`. Giải thích cú pháp C# mới (record, async/await, nullable, LINQ). Giải thích thêm các hàm kế thừa lạ hoặc những kiểu dữ liệu lạ |
| **Comment kiểu doanh nghiệp**  | Comment nói _mục đích_ (vì sao), không diễn giải từng dòng. Code sạch, đặt tên rõ ràng, không viết tắt khó hiểu. Viết bằng tiếng anh                                                                                                                         |
| **Đi đúng thứ tự task**        | Không làm trước task sau. Không thêm thư viện, interface, abstraction "để sau dùng".                                                                                                                                                                         |
| **Khi review code người dùng** | Chỉ ra lỗi, giải thích nguyên nhân, gợi ý hướng sửa. Để người dùng tự sửa trước khi đưa đáp án.                                                                                                                                                              |

---

## 2. Bản đồ repo

| Đường dẫn                         | Chứa gì                                                                               |
| --------------------------------- | ------------------------------------------------------------------------------------- |
| `BankingSystem.Api/Features/<X>/` | Một nghiệp vụ: `XController`, `IXService`, `XService`, `XRepository`, `Dtos/`         |
| `BankingSystem.Api/Domain/`       | Entity + enum dùng chung từ 2 feature trở lên                                         |
| `BankingSystem.Api/Data/`         | Nơi **duy nhất** kết nối SQL Server và gọi stored procedure                           |
| `BankingSystem.Api/Common/`       | Envelope, xử lý lỗi toàn cục, bảng mã lỗi, JSON converter, phân trang, `ICurrentUser` |
| `BankingSystem.Tests/`            | Integration test (HTTP + DB thật) và unit test (logic thuần)                          |
| `database/src/<module>/*.sql`     | Stored procedure: **tên tham số, cột trả về, mã lỗi**                                 |
| `database/src/view/*.sql`         | View: danh sách cột để viết `ResponseDto`                                             |
| `database/deploy.ps1`             | Xoá và dựng lại DB từ đầu                                                             |
| `docs/`                           | SRS, system design, pipeline, API contract                                            |

---

## 3. Quy tắc kỹ thuật bắt buộc

1. **Proc là nguồn sự thật.** Mọi thao tác ghi đi qua `dbo.sp_*`. Không EF Core, không `DbContext`, không Migrations, không viết SQL thay đổi số dư trong C#.
2. **Một request = một lần gọi proc ghi.** Proc tự `BEGIN/COMMIT/ROLLBACK`; app không mở transaction.
3. **Chỉ `Data/` dùng `Microsoft.Data.SqlClient`.**
4. **Phụ thuộc giữa feature đi qua interface:** feature A gọi `IBService`, không gọi `BRepository`.
5. **Tên tham số proc:** luôn mở file `.sql` để lấy đúng tên (`@branch_name`…), không đoán. Vài file có tên gõ sai sẵn (`customer_create_profie.sql`); tên proc thật nằm trong câu `CREATE OR ALTER PROCEDURE`.
6. **Định dạng dữ liệu theo [`docs/api_contract.md`](docs/api_contract.md):** tiền là chuỗi 2 chữ số lẻ, ngày không offset, enum đúng chuỗi gốc, id `NCHAR` phải `.Trim()`.
7. **Không bao giờ trả ra client:** `password_hash`, `cvv_hash`, `otp_code`. Số thẻ đầy đủ chỉ trong response phát hành thẻ.
8. **Proc mới:** viết `dbo.sp_xxx` (thiếu `dbo.` sẽ lỗi Msg 208 khi deploy DB mới), mã `THROW` 6 chữ số ≥ 50000.
9. **Constructor kiểu truyền thống, không dùng primary constructor.** Class khai báo `private readonly _field` + constructor tường minh (`public XService(IXRepository repository) { _repository = repository; }`); đặt tên field bắt đầu bằng `_`. Không viết `class X(IDep dep)`. Riêng `record` (DTO, entity) vẫn dùng cú pháp positional bình thường.
10. **Kiểm chứng thật:** "build được" chưa phải là xong. Phải đạt tiêu chí nghiệm thu của task và Definition of Done ([`docs/pipeline.md`](docs/pipeline.md) §3.2). Sửa DB thì chạy `pwsh -File database/deploy.ps1 -Seed`; "chạy được trong SSMS" không phải là bằng chứng.

---

## 4. Lệnh thường dùng

```bash
pwsh -File database/deploy.ps1 -Seed          # dựng lại DB + dữ liệu mẫu (SQLEXPRESS01)
dotnet build                                  # từ thư mục gốc
dotnet test                                   # chạy toàn bộ test
dotnet run --project BankingSystem.Api        # chạy API, mở /swagger
```

---

## 5. Cách làm một task

1. **Đọc** task trong `PLAN.md` và use case liên quan trong SRS. Khái niệm nào chưa hiểu thì hỏi để được _giải thích_, chưa xin code vội.
2. **Mở file `.sql`** của proc liên quan, ghi ra: tên proc, tham số, cột trả về, mã lỗi.
3. **Tự viết code**: Repository → Service → Controller. Bí quá 20–30 phút mới hỏi gợi ý.
4. **Viết test** theo tiêu chí nghiệm thu của task. Test là bắt buộc; chỉ thứ tự là code trước, test sau.
5. **Chạy** `deploy.ps1 -Seed` + `dotnet test` cho tới khi xanh.
6. **Tự giải thích lại** bằng lời: "file này làm gì, vì sao cần nó". Không nói được nghĩa là chưa hiểu.
7. **Commit**: agent gợi ý lệnh với message trong task, người dùng tự chạy; sau đó đánh dấu `- [x]` trong `PLAN.md`.

---

## 6. Lỗi hay gặp

| Triệu chứng                                               | Nguyên nhân / cách sửa                                                                                    |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| ID trả về `"BR00000001  "` có khoảng trắng                | Cột `NCHAR` pad khoảng trắng, quên `.Trim()`                                                              |
| Lỗi SSL/handshake khi kết nối DB                          | Thiếu `TrustServerCertificate=True` trong connection string                                               |
| `Procedure expects parameter '@x' which was not supplied` | Sai tên tham số, mở file `.sql` đối chiếu                                                                 |
| `Msg 208 Invalid object name` khi deploy                  | Proc thiếu `dbo.` trong `CREATE OR ALTER PROCEDURE`                                                       |
| Tiền ra JSON dạng `1000.5` (number)                       | Chưa đăng ký converter tiền → chuỗi                                                                       |
| Ngày ra `...+07:00`                                       | Gọi `.ToLocalTime()` / `ToUniversalTime()`, hoặc thiếu converter ngày                                     |
| Test không compile vì `Program`                           | Thiếu `public partial class Program { }` cuối `Program.cs`                                                |
| Có token mà vẫn `401`                                     | `UseAuthentication()` đặt sau `UseAuthorization()`, hoặc secret/issuer lúc phát và lúc kiểm tra khác nhau |
| Lỗi trả về trang HTML thay vì JSON                        | Chưa đăng ký exception handler toàn cục                                                                   |
