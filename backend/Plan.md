# backend/Plan.md — Hướng dẫn dựng Spring Boot API

> **File này khác `PLAN.md` ở gốc repo.**
> - `../PLAN.md` = **hợp đồng / spec**: định dạng ID–tiền–enum–ngày–lỗi (§1), danh sách endpoint đầy đủ (Phụ lục A), bảng mã lỗi (Phụ lục B). Là **nguồn sự thật**, không chép lại vào đây.
> - `backend/Plan.md` (file này) = **cầm tay chỉ việc**: tạo project, cây thư mục, từng file làm gì, viết theo thứ tự nào, chạy & test ra sao.
>
> Trước khi code: đọc `../PLAN.md` §1 (contract), §3 (backend), Phụ lục A + B. Roadmap tổng ở `../PLAN.md` §5 — file này chi tiết hoá **Phase 2** (skeleton + 1 lát cắt dọc `sp_branch_create`).

---

## Mục lục

- [0. Nguyên tắc kiến trúc (đọc 1 lần)](#0-nguyên-tắc-kiến-trúc-đọc-1-lần)
  - [0.1 Spring Boot 4 — khác gì tài liệu 3.x](#01-spring-boot-4--khác-gì-tài-liệututorial-3x)
- [1. Chuẩn bị máy](#1-chuẩn-bị-máy)
- [2. Tạo project + `pom.xml`](#2-tạo-project--pomxml)
- [3. Cây thư mục đầy đủ](#3-cây-thư-mục-đầy-đủ)
- [4. `application.yml` + kết nối DB](#4-applicationyml--kết-nối-db)
- [5. Giải thích từng component](#5-giải-thích-từng-component)
  - [5.1 `BackendApplication`](#51-backendapplication)
  - [5.2 `db/` — nói chuyện với stored procedure](#52-db--nói-chuyện-với-stored-procedure)
  - [5.3 `common/` — envelope + xử lý lỗi](#53-common--envelope--xử-lý-lỗi)
  - [5.4 `config/` — Jackson, CORS, OpenAPI](#54-config--jackson-cors-openapi)
  - [5.5 `security/` — JWT + phân quyền (Phase 3)](#55-security--jwt--phân-quyền-phase-3)
  - [5.6 Một feature = Controller + Service + dto](#56-một-feature--controller--service--dto)
  - [5.7 `loan/AmortizationSchedule` + `saving/MaturedSavingsJob`](#57-loanamortizationschedule--savingmaturedsavingsjob)
- [6. Thứ tự viết code cho Phase 2](#6-thứ-tự-viết-code-cho-phase-2)
- [7. Chạy & test](#7-chạy--test)
- [8. Bảng tra: kiểu DB → Java → JSON](#8-bảng-tra-kiểu-db--java--json)
- [9. Checklist "Phase 2 xong"](#9-checklist-phase-2-xong)
- [10. Sau Phase 2](#10-sau-phase-2)

---

## 0. Nguyên tắc kiến trúc (đọc 1 lần)

| Nguyên tắc | Nghĩa là |
|---|---|
| **Proc là nguồn sự thật** | Mọi thao tác ghi đi qua `dbo.sp_*`. Spring **không** tự viết SQL số dư, không JPA, không `@Entity`, không repository. |
| **Service mỏng** | Mỗi service method = `validate input` → `sp.call("sp_xxx", ...)` → `map result` → `ApiResponse`. Thường 3–8 dòng. |
| **1 request = 1 proc call** | Không `@Transactional` ở Spring — proc tự `BEGIN/COMMIT/ROLLBACK`. |
| **Chỉ 1 chỗ chạm JDBC** | `StoredProcedureExecutor`. Không class nào khác `import java.sql.*`. |
| **Feature-based packaging** | Gom theo nghiệp vụ (`branch/`, `loan/`…), không theo tầng (`controllers/`, `services/`). Sửa 1 tính năng chỉ mở 1 folder. |
| **Java tự tính đúng 1 thứ** | Lịch trả góp (`AmortizationSchedule`). Còn lại proc lo hết. |
| **Không viết sẵn 60 controller** | Có 2 mẫu (Branch = CRUD, Transfer = có ownership). Nhân bản theo Phụ lục A khi tới phase tương ứng. |

Vì sao mỏng vậy: DB đã có 63 proc + 54 function validate + guarded-UPDATE chống đua. Viết lại quy tắc trong Java = 2 bản phải đồng bộ tay. Spring chỉ làm phần DB **không** làm được: HTTP/JSON, BCrypt, JWT, phân trang, đọc IP request, `@Scheduled`.

### 0.1 Spring Boot 4 — khác gì tài liệu/tutorial 3.x

Đa số tutorial ngoài kia viết cho Boot 3. Chốt dùng **Boot 4.1.1** (Initializr đã bỏ 3.x). Những chỗ sẽ lệch khi làm theo:

| Chỗ | Boot 3 (tutorial) | Boot 4 (làm theo cái này) |
|---|---|---|
| Starter web | `spring-boot-starter-web` | `spring-boot-starter-webmvc` (tên cũ còn chạy nhưng đã deprecated) |
| Starter test | 1 cục `spring-boot-starter-test` | tách nhỏ: `spring-boot-starter-webmvc-test`, `-jdbc-test`, `-security-test`, `-validation-test` |
| `spring-security-test` | `org.springframework.security:spring-security-test` | gộp trong `spring-boot-starter-security-test` |
| Swagger | springdoc-openapi **2.x** | springdoc-openapi **3.x** (`3.1.1`) — 2.x không chạy Boot 4 |
| Jackson | Jackson 2 (`com.fasterxml.jackson.*`) | **Jackson 3** (`tools.jackson.*`). `JacksonConfig` §5.4: `Jackson2ObjectMapperBuilderCustomizer` → `JsonMapperBuilderCustomizer` (bean cũ còn nhưng deprecated, bỏ ở 4.3). Chi tiết §5.4. |
| Java | thường 17 | 17 vẫn OK (baseline Boot 4); khuyến nghị 21 |
| `application.properties` | — | Initializr sinh `.properties` — xoá, tạo `application.yml` (§4) |

Còn lại (JdbcTemplate, `@RestController`, Bean Validation, Security lambda DSL `http.csrf(...).authorizeHttpRequests(...)`, `@Scheduled`) **giống hệt 3.x** — chép tutorial thoải mái.

---

## 1. Chuẩn bị máy

| Cần | Kiểm tra |
|---|---|
| JDK 17+ | `java -version` |
| Maven (hoặc dùng `./mvnw` mà Initializr tạo sẵn) | `mvn -version` |
| IntelliJ IDEA (Community đủ) | — |
| SQL Server đang chạy + đã deploy `BankingSystem` | xem dưới |

**DB cho backend dev — dùng Docker cho nhẹ đầu:**

```bash
docker compose up -d
pwsh -File database/deploy.ps1 -Docker -Seed
```

→ SQL Server ở `localhost:1433`, user `sa`, password `BankSys_2026!` (trong `docker-compose.yml`), có sẵn demo data (1 branch, 2 customer…).

> Vì sao không dùng `localhost\SQLEXPRESS01` như `deploy.ps1` mặc định: named instance + Windows auth qua JDBC cần file `mssql-jdbc_auth-*.dll` trên `java.library.path` — lằng nhằng. Docker = SQL auth, cắm phát chạy. Muốn dùng SQLEXPRESS01 thật thì phải bật Mixed Mode auth + tạo 1 login SQL, rồi đổi URL ở §4.

---

## 2. Tạo project + `pom.xml`

**Spring Initializr** (https://start.spring.io hoặc IntelliJ → New Project → Spring Boot):

| Mục | Chọn |
|---|---|
| Project | Maven |
| Language | Java |
| Spring Boot | **4.1.1** — Initializr đã bỏ 3.x (3.5 sắp hết OSS support). Xem §0.1 để biết Boot 4 khác gì tutorial 3.x. |
| Group | `com.bankingsystem` |
| Artifact | `backend` |
| Packaging | Jar |
| Java | 17 (Boot 4 baseline vẫn là 17; khuyến nghị 21 nhưng 17 chạy tốt) |
| Dependencies | **Spring Web** · **JDBC API** · **Validation** · **Spring Security** · **MS SQL Server Driver** |

> "JDBC API" = `spring-boot-starter-jdbc` (JdbcTemplate thuần). **Không** chọn "Spring Data JDBC".

Initializr sinh ra `pom.xml` gần đủ. Thêm tay **springdoc** + **jjwt**, thành:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.1.1</version>
        <relativePath/>
    </parent>

    <groupId>com.bankingsystem</groupId>
    <artifactId>backend</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>backend</name>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <!-- === Initializr sinh sẵn 5 cái này === -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webmvc</artifactId>   <!-- Boot 4: thay cho spring-boot-starter-web -->
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>com.microsoft.sqlserver</groupId>
            <artifactId>mssql-jdbc</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- === Thêm tay: Swagger UI (test tay Phase 2). Boot 4 cần springdoc 3.x === -->
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>3.1.1</version>   <!-- 2.x chỉ chạy Boot 3; check bản mới nhất khi build -->
        </dependency>

        <!-- === Thêm tay: JWT (Phase 3). Chưa dùng thì để đó. === -->
        <!-- Lưu ý Boot 4 dùng Jackson 3 (tools.jackson.*); jjwt-jackson 0.12.6 kéo Jackson 2 về,
             vẫn chạy nhưng có 2 Jackson trên classpath. Tới Phase 3 check jjwt có bản Jackson 3 chưa. -->
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.12.6</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.12.6</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.12.6</version>
            <scope>runtime</scope>
        </dependency>

        <!-- === Test — Boot 4 tách spring-boot-starter-test thành các starter con === -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webmvc-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

**Bỏ qua có chủ đích:** Lombok (dùng `record`, class ngắn), MapStruct (mapper viết tay theo view — §5.6), Flyway/Liquibase (`deploy.ps1` lo schema), JPA/Hibernate (không có entity).

---

## 3. Cây thư mục đầy đủ

Package gốc `com.bankingsystem`. `(P3)` = làm ở Phase 3, `(P7)`… = phase sau. Không có nhãn = Phase 2.

```
backend/
├── pom.xml
├── mvnw  mvnw.cmd  .mvn/                  ← Maven wrapper, Initializr tạo
├── .gitignore                             ← Initializr có sẵn target/; thêm: application-local.yml
├── Plan.md  HELP.md                       ← HELP.md của Initializr, xoá được
└── src/
    ├── main/
    │   ├── java/com/bankingsystem/
    │   │   ├── BackendApplication.java     Initializr sinh; thêm main() timezone + @EnableScheduling (§5.1)
    │   │   │
    │   │   ├── db/
    │   │   │   ├── StoredProcedureExecutor.java   CHỖ DUY NHẤT gọi {call dbo.sp_*}
    │   │   │   └── Rows.java                      ResultSet → List<Map>; trim NCHAR, parse tiền/ngày
    │   │   │
    │   │   ├── common/
    │   │   │   ├── ApiResponse.java               envelope {success,message,data,error}
    │   │   │   ├── ApiError.java                  {code, domain}
    │   │   │   ├── SqlErrorCatalog.java           mã THROW → (domain, HTTP status)
    │   │   │   ├── GlobalExceptionHandler.java    bắt SQLException + lỗi validate → envelope
    │   │   │   └── PagedResponse.java             cắt trang trong bộ nhớ (§1.9)
    │   │   │
    │   │   ├── config/
    │   │   │   ├── JacksonConfig.java             BigDecimal→string, ngày ISO không offset
    │   │   │   ├── CorsConfig.java                cho Vite dev (localhost:5173)
    │   │   │   └── OpenApiConfig.java             tiêu đề Swagger + nút Authorize (P3)
    │   │   │
    │   │   ├── security/                          (P3 — Phase 2 chỉ cần SecurityConfig mở hết)
    │   │   │   ├── SecurityConfig.java
    │   │   │   ├── JwtService.java                phát + verify token
    │   │   │   ├── JwtAuthFilter.java             đọc header Authorization mỗi request
    │   │   │   ├── AccountPrincipal.java          record: accountId, username, role
    │   │   │   └── OwnershipGuard.java            "TK này có phải của người đăng nhập?"
    │   │   │
    │   │   ├── branch/                            ★ MẪU 1 — CRUD thuần
    │   │   │   ├── BranchController.java
    │   │   │   ├── BranchService.java
    │   │   │   └── dto/
    │   │   │       ├── CreateBranchRequest.java
    │   │   │       ├── UpdateBranchRequest.java
    │   │   │       └── BranchResponse.java
    │   │   │
    │   │   ├── auth/            (P3)  register→otp→activate→login, /me, đổi/quên mật khẩu
    │   │   ├── customer/        (P4)
    │   │   ├── employee/        (P4)
    │   │   ├── bankingaccount/  (P5)
    │   │   ├── card/            (P5)
    │   │   ├── transaction/     (P6)  ★ MẪU 2 — có OwnershipGuard, phần đồng thời trọng yếu
    │   │   ├── loan/            (P7)  + AmortizationSchedule.java  (Java tự tính)
    │   │   ├── saving/          (P8)  + MaturedSavingsJob.java     (@Scheduled)
    │   │   ├── beneficiary/     (P9)
    │   │   ├── notification/    (P9)
    │   │   ├── loginhistory/    (P3)
    │   │   └── admin/           (P10)
    │   │
    │   └── resources/
    │       ├── application.yml                    config chung (commit được)
    │       └── application-local.yml              password thật — .gitignore, KHÔNG commit
    │
    └── test/java/com/bankingsystem/
        ├── BackendApplicationTests.java           Initializr sinh (contextLoads) — giữ, nó check bean load OK
        ├── branch/BranchApiIT.java                integration test lát cắt dọc
        └── loan/AmortizationScheduleTest.java     (P7) Σ principal == principal, dư nợ cuối == 0
```

**Quy ước đặt tên trong 1 feature package** (giống hệt nhau cho cả 13 module):

| File | Vai trò | Chứa gì |
|---|---|---|
| `XxxController.java` | Nhận HTTP, không có logic | `@RestController`, `@RequestMapping("/api/xxx")`, mỗi method map 1 endpoint Phụ lục A, gọi thẳng service, trả `ApiResponse<T>` |
| `XxxService.java` | Điều phối | Gọi `OwnershipGuard` (nếu cần) → `sp.call(...)` → `map(row)` → `ApiResponse.ok/…` |
| `dto/CreateXxxRequest.java` | Input | `record` + Bean Validation (`@NotBlank`, `@DecimalMin`…). Field **camelCase**. |
| `dto/XxxResponse.java` | Output | `record` mirror đúng cột của `vw_Xxx` tương ứng, đổi sang camelCase (§1.7). |

---

## 4. `application.yml` + kết nối DB

> Initializr sinh `src/main/resources/application.properties` (chỉ có 1 dòng `spring.application.name`). **Xoá nó**, tạo `application.yml` dưới đây.

`src/main/resources/application.yml`:

```yaml
spring:
  application:
    name: banking-system
  datasource:
    url: jdbc:sqlserver://localhost:1433;databaseName=BankingSystem;encrypt=false;trustServerCertificate=true
    username: sa
    password: ${DB_PASSWORD:BankSys_2026!}     # override bằng biến môi trường khi cần
    hikari:
      pool-name: banking-pool
      maximum-pool-size: 10
  jackson:
    default-property-inclusion: non_null       # ẩn field null trong JSON

server:
  port: 8080
  error:
    include-message: never                     # lỗi phải đi qua GlobalExceptionHandler, không lộ stacktrace
    include-stacktrace: never

springdoc:
  swagger-ui:
    path: /swagger-ui.html
    operations-sorter: method

app:
  jwt:
    secret: ${JWT_SECRET:dev-only-secret-please-change-min-32-bytes-long}
    ttl-minutes: 60
```

> **Timezone (§1.4):** cả JVM và SQL Server phải hiểu giờ `Asia/Ho_Chi_Minh`. Cách chắc ăn nhất: đặt trong `main()` **trước** `SpringApplication.run` (xem §5.1). Hoặc chạy với `-Duser.timezone=Asia/Ho_Chi_Minh`.

> **URL cho named instance** (nếu không dùng Docker):
> `jdbc:sqlserver://localhost;instanceName=SQLEXPRESS01;databaseName=BankingSystem;encrypt=false;trustServerCertificate=true`
> — cần dịch vụ **SQL Server Browser** đang chạy + 1 login SQL (Windows auth qua JDBC phải kèm DLL).

**`encrypt=false;trustServerCertificate=true`** bắt buộc: driver mssql-jdbc 10+ mặc định `encrypt=true`, gặp self-signed cert của SQL Server local sẽ ném lỗi handshake.

---

## 5. Giải thích từng component

### 5.1 `BackendApplication`

Initializr sinh sẵn class này (tên `BackendApplication`, package `com.bankingsystem`). Chỉ thêm 2 dòng: set timezone (§1.4) + `@EnableScheduling`.

```java
package com.bankingsystem;

import java.util.TimeZone;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling                 // cho MaturedSavingsJob (Phase 8). Vô hại nếu chưa có job.
public class BackendApplication {
    public static void main(String[] args) {
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Ho_Chi_Minh"));   // §1.4
        SpringApplication.run(BackendApplication.class, args);
    }
}
```

- `@SpringBootApplication` = `@Configuration` + `@ComponentScan` (quét mọi class có `@Component/@Service/@RestController` trong `com.bankingsystem.**`) + `@EnableAutoConfiguration` (tự cấu hình Tomcat, DataSource, Jackson… từ `application.yml`).
- Đặt file này ở **package gốc** để `@ComponentScan` thấy hết feature package con.

### 5.2 `db/` — nói chuyện với stored procedure

**`Rows.java`** — chuyển `ResultSet` sang `List<Map>` và ép kiểu đúng contract §1:

```java
package com.bankingsystem.db;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.time.*;
import java.util.*;

public final class Rows {
    private Rows() {}

    public static List<Map<String, Object>> toMaps(ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        int n = md.getColumnCount();
        List<Map<String, Object>> out = new ArrayList<>();
        while (rs.next()) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= n; i++) row.put(md.getColumnLabel(i), rs.getObject(i));
            out.add(row);
        }
        return out;
    }

    // NCHAR(10) pad khoảng trắng → luôn .trim() (§1.1)
    public static String str(Map<String, Object> m, String k) {
        Object v = m.get(k);
        return v == null ? null : v.toString().trim();
    }
    public static Long lng(Map<String, Object> m, String k) {
        Object v = m.get(k);
        return v == null ? null : ((Number) v).longValue();
    }
    public static BigDecimal money(Map<String, Object> m, String k) {           // §1.2
        Object v = m.get(k);
        return v == null ? null : new BigDecimal(v.toString()).setScale(2, RoundingMode.HALF_UP);
    }
    public static LocalDateTime dt(Map<String, Object> m, String k) {           // DATETIME (§1.4)
        Object v = m.get(k);
        return v == null ? null : ((Timestamp) v).toLocalDateTime();
    }
    public static LocalDate date(Map<String, Object> m, String k) {             // DATE
        Object v = m.get(k);
        return v == null ? null : ((java.sql.Date) v).toLocalDate();
    }
}
```

**`StoredProcedureExecutor.java`** — điểm tiếp xúc DUY NHẤT với `sp_*`:

```java
package com.bankingsystem.db;

import java.sql.*;
import java.util.*;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class StoredProcedureExecutor {

    private final JdbcTemplate jdbc;
    public StoredProcedureExecutor(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    /** Gọi {call dbo.<proc>(?, ?, …)}; trả các dòng của result set đầu tiên. */
    public List<Map<String, Object>> call(String proc, Object... args) {
        String ph = args.length == 0 ? "" :
            String.join(", ", Collections.nCopies(args.length, "?"));
        String sql = "{call dbo." + proc + "(" + ph + ")}";     // 'dbo.' bắt buộc — xem memory
        return jdbc.execute((ConnectionCallback<List<Map<String, Object>>>) con -> {
            try (CallableStatement cs = con.prepareCall(sql)) {
                for (int i = 0; i < args.length; i++) cs.setObject(i + 1, args[i]);
                if (!cs.execute()) return List.of();
                try (ResultSet rs = cs.getResultSet()) { return Rows.toMaps(rs); }
            }
        });
    }

    /** Dòng đầu; ném nếu proc không trả gì (proc thành công LUÔN SELECT ... 'message'). */
    public Map<String, Object> one(String proc, Object... args) {
        List<Map<String, Object>> rows = call(proc, args);
        if (rows.isEmpty()) throw new IllegalStateException(proc + " trả về 0 dòng");
        return rows.get(0);
    }

    public String message(Map<String, Object> row) {
        Object m = row.containsKey("message") ? row.get("message") : row.get("result_message");
        return m == null ? null : m.toString();
    }
}
```

Vì sao `JdbcTemplate` + `ConnectionCallback` thô chứ không `SimpleJdbcCall`: proc trả **result set** (không dùng OUT param), và ta cần đọc `message` ở cột cuối. Cách này ngắn, rõ, 1 lần viết.

Vì sao **không** khai báo tên param (`@branch_name`…): `cs.setObject(i+1, ...)` truyền **theo thứ tự**. Nên khi gọi phải xếp `args` **đúng thứ tự tham số trong file `.sql`**. Luôn mở file proc ra đối chiếu.

### 5.3 `common/` — envelope + xử lý lỗi

**`ApiResponse` / `ApiError`** — mọi endpoint trả kiểu này (§1.6):

```java
package com.bankingsystem.common;

public record ApiResponse<T>(boolean success, String message, T data, ApiError error) {
    public static <T> ApiResponse<T> ok(String message, T data)  { return new ApiResponse<>(true, message, data, null); }
    public static <T> ApiResponse<T> fail(String message, ApiError e) { return new ApiResponse<>(false, message, null, e); }
}
```
```java
package com.bankingsystem.common;
public record ApiError(int code, String domain) {}
```

**`SqlErrorCatalog`** — map số `THROW` của proc → domain + HTTP status. **Dải mã đầy đủ ở `../PLAN.md` §3.2 + Phụ lục B** — chép nguyên bảng `BANDS` từ đó. Ý tưởng:

```java
public static Entry lookup(int code) {
    if (code < 50000) return new Entry("system", HttpStatus.INTERNAL_SERVER_ERROR);
    // first-match trong danh sách dải [lo, hi] → (domain, status). Xem PLAN.md §3.2.
    // mã kết thúc ...000 + message chứa "does not exist"/"Invalid" → handler override thành 404.
}
```
Có 2 hệ mã (5 chữ số cũ cho branch/card/customer/employee/loan; 6 chữ số cho phần còn lại) — catalog xử lý cả hai. Proc **mới** phải ≥ 50000 (xem memory *THROW error number range*).

**`GlobalExceptionHandler`** — 1 chỗ biến exception thành envelope:

```java
package com.bankingsystem.common;

import java.sql.SQLException;
import org.springframework.core.NestedExceptionUtils;
import org.springframework.dao.DataAccessException;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(DataAccessException.class)     // mọi lỗi từ proc (THROW) rơi vào đây
    public ResponseEntity<ApiResponse<Void>> onSql(DataAccessException ex) {
        Throwable cause = NestedExceptionUtils.getMostSpecificCause(ex);
        int code = (cause instanceof SQLException se) ? se.getErrorCode() : 0;
        var entry = SqlErrorCatalog.lookup(code);
        String msg = cleanMessage(cause.getMessage());   // bỏ "... Line 42" của T-SQL
        HttpStatus http = looksLikeNotFound(msg) ? HttpStatus.NOT_FOUND : entry.status();
        return ResponseEntity.status(http)
            .body(ApiResponse.fail(msg, new ApiError(code, entry.domain())));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)   // Bean Validation fail → 400
    public ResponseEntity<ApiResponse<Void>> onInvalid(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
            .map(f -> f.getField() + ": " + f.getDefaultMessage())
            .reduce((a, b) -> a + "; " + b).orElse("Invalid request");
        return ResponseEntity.badRequest()
            .body(ApiResponse.fail(msg, new ApiError(400, "validation")));
    }
}
```
Nhờ handler này, service **không cần try/catch** — cứ gọi proc, lỗi tự thành JSON đúng format.

**`PagedResponse`** — proc `*_search` trả hết dòng; Spring cắt trang trong RAM (§1.9): nhận `?page=0&size=20&sort=createdAt,desc`, trả `data` = array trang hiện tại + header `X-Total-Count`. Chưa cần cho Phase 2.

### 5.4 `config/` — Jackson, CORS, OpenAPI

**`JacksonConfig`** — ép JSON theo §1.2/§1.4.

> ⚠️ **Boot 4 = Jackson 3.** Code dưới viết cho Jackson 2 (`Jackson2ObjectMapperBuilderCustomizer`, `com.fasterxml.jackson.*`). Bean cũ vẫn chạy trên Boot 4 nhưng deprecated (bỏ ở 4.3). Cách chuẩn Boot 4:
> - Đổi `Jackson2ObjectMapperBuilderCustomizer` → **`JsonMapperBuilderCustomizer`**, import `tools.jackson.databind.*` thay `com.fasterxml.jackson.databind.*`.
> - **Đơn giản & bền hơn:** bỏ luôn serializer BigDecimal ở đây, chỉ gắn `@JsonFormat(shape = JsonFormat.Shape.STRING)` lên từng field `BigDecimal` trong `*Response` record (annotation này giống nhau ở Jackson 2 lẫn 3). Ngày tháng: `@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")` hoặc để `DateTimeFormatter` mặc định ISO (đã không offset sẵn với `LocalDateTime`).
> - Chốt lại lúc viết Phase 2 bước 5 — build thử rồi khoá cách làm.

```java
// Jackson 2 style (chạy được nhưng deprecated trên Boot 4):
@Bean
Jackson2ObjectMapperBuilderCustomizer json() {
    return b -> {
        b.serializerByType(BigDecimal.class, ToStringSerializer.instance);   // tiền → "1000000.00"
        b.serializers(new LocalDateTimeSerializer(
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")));          // không offset
        b.serializers(new LocalDateSerializer(DateTimeFormatter.ISO_LOCAL_DATE));
    };
}
```

**`CorsConfig`** — cho React Vite gọi khi dev:

```java
@Bean
WebMvcConfigurer cors() {
    return new WebMvcConfigurer() {
        public void addCorsMappings(CorsRegistry r) {
            r.addMapping("/api/**").allowedOrigins("http://localhost:5173")
             .allowedMethods("GET","POST","PUT","DELETE").exposedHeaders("X-Total-Count");
        }
    };
}
```

**`OpenApiConfig`** — đặt tiêu đề + (P3) nút Authorize để dán JWT vào Swagger. Phase 2 để trống cũng được, springdoc tự sinh `/swagger-ui.html`.

### 5.5 `security/` — JWT + phân quyền (Phase 3)

**Phase 2**: chỉ cần `SecurityConfig` mở hết để test `/api/branches` không cần token:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    SecurityFilterChain chain(HttpSecurity http) throws Exception {
        http.csrf(c -> c.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .anyRequest().permitAll());          // Phase 2: mở hết. Phase 3 siết lại.
        return http.build();
    }
}
```

**Phase 3** thêm (chi tiết ở `../PLAN.md` §1.10 + §3):

| Class | Việc |
|---|---|
| `JwtService` | `issue(AccountPrincipal)` khi login OK · `parse(token)` trong filter. HS256, secret + TTL từ `app.jwt.*`. |
| `JwtAuthFilter` | `OncePerRequestFilter`: đọc `Authorization: Bearer …` → set `SecurityContext`. |
| `AccountPrincipal` | `record(Long accountId, String username, String role)` — `@AuthenticationPrincipal` bơm vào controller. |
| `OwnershipGuard` | `assertOwnsBankAccount(me, id)` — query nhẹ qua `fn_*_validate_owner` / view; sai → ném 403. |
| `PasswordConfig` | `@Bean BCryptPasswordEncoder`. |
| `SecurityConfig` (sửa) | thêm `JwtAuthFilter`, `@EnableMethodSecurity`, đổi `anyRequest().permitAll()` → rule theo route. |

`login` **so mật khẩu ở Spring** (`passwordEncoder.matches`), không để proc so — vì proc chỉ so `password_hash = @password` chuỗi thẳng.

### 5.6 Một feature = Controller + Service + dto

**Mẫu 1 — `branch/` (CRUD thuần).** `sp_branch_create(@branch_name, @address, @phone_number)` → `SELECT * FROM vw_Branch ... , 'Branch created successfully.' AS message`.

`dto/CreateBranchRequest.java`:
```java
package com.bankingsystem.branch.dto;
import jakarta.validation.constraints.*;

public record CreateBranchRequest(
    @NotBlank @Size(max = 100) String branchName,
    @NotBlank @Size(max = 100) String address,
    @NotBlank @Size(max = 20)  String phoneNumber
) {}
```

`dto/BranchResponse.java` — mirror `vw_Branch` (7 cột: `branch_id, branch_name, address, phone_number, created_at, updated_at, status`) đổi sang camelCase:
```java
package com.bankingsystem.branch.dto;
import java.time.LocalDateTime;

public record BranchResponse(
    String branchId, String branchName, String address, String phoneNumber,
    LocalDateTime createdAt, LocalDateTime updatedAt, String status
) {}
```

`BranchService.java`:
```java
package com.bankingsystem.branch;

import java.util.Map;
import org.springframework.stereotype.Service;
import com.bankingsystem.branch.dto.*;
import com.bankingsystem.common.ApiResponse;
import com.bankingsystem.db.Rows;
import com.bankingsystem.db.StoredProcedureExecutor;

@Service
public class BranchService {

    private final StoredProcedureExecutor sp;
    public BranchService(StoredProcedureExecutor sp) { this.sp = sp; }

    public ApiResponse<BranchResponse> create(CreateBranchRequest r) {
        Map<String, Object> row = sp.one("sp_branch_create",
            r.branchName(), r.address(), r.phoneNumber());     // ĐÚNG thứ tự param trong .sql
        return ApiResponse.ok(sp.message(row), map(row));
    }

    private BranchResponse map(Map<String, Object> m) {
        return new BranchResponse(
            Rows.str(m, "branch_id"),   Rows.str(m, "branch_name"),
            Rows.str(m, "address"),     Rows.str(m, "phone_number"),
            Rows.dt(m, "created_at"),   Rows.dt(m, "updated_at"),
            Rows.str(m, "status"));
    }
}
```

`BranchController.java`:
```java
package com.bankingsystem.branch;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.bankingsystem.branch.dto.*;
import com.bankingsystem.common.ApiResponse;

@RestController
@RequestMapping("/api/branches")
public class BranchController {

    private final BranchService service;
    public BranchController(BranchService service) { this.service = service; }

    @PostMapping
    // @PreAuthorize("hasRole('ADMIN')")   // bật ở Phase 3
    public ApiResponse<BranchResponse> create(@Valid @RequestBody CreateBranchRequest req) {
        return service.create(req);
    }
}
```

Các endpoint branch còn lại (`PUT /{id}`, `PUT /{id}/status`, `GET /{id}`, `GET /{id}/summary`, `GET ?name=&status=` — xem Phụ lục A) = copy y hệt cấu trúc trên, đổi proc + dto.

**Mẫu 2 — `transaction/` (có ownership, Phase 6).** Khác mẫu 1 ở 2 điểm — xem `../PLAN.md` §3.3:
```java
@PostMapping("/transfer")
public ApiResponse<TransactionResponse> transfer(@Valid @RequestBody TransferRequest req,
                                                 @AuthenticationPrincipal AccountPrincipal me) {
    ownership.assertOwnsBankAccount(me, req.fromBankAccountId());   // (1) chặn thao tác TK người khác
    Map<String,Object> row = sp.one("sp_bank_transaction_transfer",
        req.fromBankAccountId(), req.toBankAccountId(),
        req.amount(), req.fee() == null ? BigDecimal.ZERO : req.fee(), req.description());
    notifier.afterTransfer(row);                                    // (2) bắn Notification (Phase 9, best-effort)
    return ApiResponse.ok(sp.message(row), TransactionResponse.from(row));
}
```
Phần đồng thời (20 lệnh transfer song song vượt số dư) do **guarded UPDATE trong proc** lo — Spring không làm gì thêm. Test kịch bản này ở `../PLAN.md` §6.

### 5.7 `loan/AmortizationSchedule` + `saving/MaturedSavingsJob`

**Toàn bộ** phần Java "tự làm logic". Code đầy đủ + test ở `../PLAN.md` §3.5 — chép từ đó khi tới Phase 7/8.

- **`AmortizationSchedule`** (Phase 7): lịch trả góp cho `GET /loans/{id}/schedule`. Khớp công thức `sp_loan_apply` (§1.3): `r = annual/12/100`; `M = P·r·(1+r)^n / ((1+r)^n − 1)`; `r=0` → `M = P/n`; kỳ cuối nuốt phần lẻ để dư nợ = 0. **Không** tạo bảng `LoanRepaymentSchedule` — tính runtime, YAGNI (`../PLAN.md` §2.1).
- **`MaturedSavingsJob`** (Phase 8): `@Scheduled(cron="0 5 0 * * *", zone="Asia/Ho_Chi_Minh")` gọi `sp_saving_account_settle_matured` mỗi 00:05. Không tiến trình riêng, không thư viện ngoài. Proc này nếu DB chưa có thì thêm bản tối giản (`../PLAN.md` §2.1).

---

## 6. Thứ tự viết code cho Phase 2

Làm đúng thứ tự này — mỗi bước có mốc "chạy được" trước khi sang bước sau:

| # | Viết | Xong khi |
|---|---|---|
| 1 | `pom.xml` (springdoc + jjwt) + sửa `BackendApplication` (§5.1) + xoá `application.properties`, tạo `application.yml` (chưa cần `app.jwt`) | `./mvnw spring-boot:run` → log `Started BackendApplication`, cổng 8080 lên. Chưa có endpoint cũng OK. |
| 2 | `db/Rows` + `db/StoredProcedureExecutor` | compile sạch (`mvn compile`). |
| 3 | `common/ApiResponse` + `common/ApiError` | compile sạch. |
| 4 | `common/SqlErrorCatalog` (chép bảng dải từ `../PLAN.md` §3.2) + `common/GlobalExceptionHandler` | compile sạch. |
| 5 | `config/JacksonConfig` | restart app, không lỗi bean. |
| 6 | `security/SecurityConfig` (bản "mở hết" §5.5) | restart, `/` trả 404 (không phải 401/redirect login). |
| 7 | `branch/dto/*` → `branch/BranchService` → `branch/BranchController` | restart, `/swagger-ui.html` hiện `POST /api/branches`. |
| 8 | Test tay trên Swagger (§7) | body trả `{"success":true,"message":"Branch created successfully.","data":{...}}`. |
| 9 | Thử input rỗng `branchName` → nhận `400` + `error.code:400`. Thử `phoneNumber` quá 20 ký tự. | envelope lỗi đúng format. |
| 10 | `test/branch/BranchApiIT` (§7) | `mvn test` xanh. |

Sau bước 10: Phase 2 xong. Các module khác = lặp bước 7 theo Phụ lục A.

---

## 7. Chạy & test

**Chạy:**
```bash
cd backend
./mvnw spring-boot:run
```
Hoặc trong IntelliJ: Run `BackendApplication`.

**Swagger UI:** http://localhost:8080/swagger-ui.html → `POST /api/branches` → Try it out:
```json
{ "branchName": "Chi nhánh Quận 1", "address": "12 Lê Lợi, Q1, TP.HCM", "phoneNumber": "02838220001" }
```

**Hoặc curl:**
```bash
curl -X POST http://localhost:8080/api/branches -H "Content-Type: application/json" -d "{\"branchName\":\"Chi nhánh Quận 1\",\"address\":\"12 Le Loi\",\"phoneNumber\":\"02838220001\"}"
```

**Integration test** `src/test/java/com/bankingsystem/branch/BranchApiIT.java`:
```java
package com.bankingsystem.branch;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import com.bankingsystem.branch.dto.CreateBranchRequest;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BranchApiIT {

    @Autowired TestRestTemplate http;

    @Test
    void create_branch_returns_envelope() {
        var body = new CreateBranchRequest("Chi nhánh Test", "1 Nguyễn Huệ", "02838220099");
        var res = http.postForObject("/api/branches", body, java.util.Map.class);

        assertThat(res.get("success")).isEqualTo(true);
        assertThat(res.get("message")).isEqualTo("Branch created successfully.");
        assertThat((java.util.Map<?,?>) res.get("data")).containsKey("branchId");
    }
}
```

```bash
./mvnw test
```

> Test này **ghi 1 dòng branch thật** vào DB dev. Chấp nhận được cho đồ án học — chạy lại `pwsh -File database/deploy.ps1 -Docker -Seed` để reset.
> `ponytail:` chưa dùng Testcontainers — thêm ở Phase 11 (CI) khi cần DB sạch mỗi lần chạy.

---

## 8. Bảng tra: kiểu DB → Java → JSON

Chi tiết + lý do ở `../PLAN.md` §1. Tóm tắt cho lúc viết `map(row)`:

| Cột DB | Kiểu SQL | Đọc bằng | Field Java | JSON |
|---|---|---|---|---|
| `branch_id`, `customer_id`, `employee_id` | `NCHAR(10)` | `Rows.str` (**có trim**) | `String` | `"BR00000001"` |
| `bank_account_id`, `transaction_id`, `loan_id`… | `BIGINT` | `Rows.lng` | `Long` | `42` (number) |
| `bank_account_number` | `NCHAR(20)` | `Rows.str` | `String` | `"0001234500000000000"` (giữ leading zero) |
| `card_number` | `VARCHAR(20)` | `Rows.str` | `String` | mask `"400000******1234"` — trừ response `POST /api/cards` (§1.8) |
| `balance`, `amount`, `fee`, `interest_rate` | `DECIMAL(18,2)` | `Rows.money` | `BigDecimal` | `"1000000.00"` (**string**, 2 số lẻ) |
| `created_at`, `updated_at` | `DATETIME` | `Rows.dt` | `LocalDateTime` | `"2026-09-09T14:30:00"` (không offset) |
| `date_of_birth`, `maturity_date` | `DATE` | `Rows.date` | `LocalDate` | `"2026-09-09"` |
| `status`, `role`, `transaction_type`… | lookup string | `Rows.str` | `String` | đúng chuỗi gốc, kể cả `"Loan Officer"` (§1.5) |

**Không bao giờ** map ra response: `password_hash`, `cvv_hash`, `otp_code` (§1.8, §1.10).

---

## 9. Checklist "Phase 2 xong"

- [ ] `./mvnw spring-boot:run` lên cổng 8080, không lỗi bean/DataSource.
- [ ] `/swagger-ui.html` mở được, thấy `POST /api/branches`.
- [ ] `POST /api/branches` hợp lệ → `200` + `{success:true, message:"Branch created successfully.", data:{branchId:"BR…", …}}`.
- [ ] `branchName` rỗng → `400` + `{success:false, error:{code:400, domain:"validation"}}`.
- [ ] Tắt SQL Server → gọi API → `500` + envelope (không phải stacktrace HTML).
- [ ] `./mvnw test` xanh (`BranchApiIT`).
- [ ] Không class nào ngoài `db/` `import java.sql.*`.
- [ ] `application-local.yml` / `target/` đã trong `.gitignore`.
- [ ] Commit: `backend/` skeleton + branch slice.

---

## 10. Sau Phase 2

| Phase | Thêm gì | Tài liệu |
|---|---|---|
| 3 | `security/*` đầy đủ, `auth/` (register→otp→activate→login→`/me`), `loginhistory/` | `../PLAN.md` §1.10, §3, roadmap Phase 3 |
| 4 | `customer/`, `employee/`, phần còn lại `branch/` | Phụ lục A |
| 5 | `bankingaccount/`, `card/` | Phụ lục A |
| 6 | `transaction/` (Mẫu 2) — **test đồng thời bắt buộc** | `../PLAN.md` §1.11, §6 |
| 7 | `loan/` + `AmortizationSchedule` + test | `../PLAN.md` §3.5 |
| 8 | `saving/` + `MaturedSavingsJob` `@Scheduled` | `../PLAN.md` §3.5 |
| 9 | `beneficiary/`, `notification/` (bắn sau transfer/loan, best-effort) | Phụ lục A |
| 10 | `admin/` + endpoint thống kê dashboard | Phụ lục A |
| 11 | Gửi OTP email thật, rate-limit + khoá login, Testcontainers, CI | roadmap Phase 11 |

**Cách nhân bản:** mỗi endpoint trong Phụ lục A = 1 method controller + 1 method service + dto. Mở file `.sql` của proc để lấy **đúng thứ tự tham số**, mở file `vw_*.sql` để lấy **đúng danh sách cột** cho `Response`. Không có logic mới — chỉ nối HTTP ↔ proc.
