# Tài liệu dự án Banking System

Mỗi file trả lời một câu hỏi. Đọc theo thứ tự từ trên xuống.

| # | File | Tên gọi trong ngành | Trả lời câu hỏi |
|---|---|---|---|
| 1 | [`SRS/01_SRS.md`](SRS/01_SRS.md) | **SRS**: Software Requirements Specification | Hệ thống phải làm gì? Ai dùng? Use case, yêu cầu, quy tắc nghiệp vụ |
| 2 | [`system_design.md`](system_design.md) | **SDD**: System Design Document / Technical Design Doc | Hệ thống được xây thế nào và vì sao? Kiến trúc, cấu trúc thư mục, quyết định thiết kế |
| 3 | [`pipeline.md`](pipeline.md) | Runtime flow + **CI/CD pipeline** | Một request / nghiệp vụ chạy qua đâu? Code đi từ máy tới bản chạy thế nào? |
| 4 | [`api_contract.md`](api_contract.md) | **API Contract** / Interface Spec | Định dạng JSON, endpoint, mã lỗi chính xác là gì? |
| 5 | [`schema.md`](schema.md) | Database Design | Các bảng được thiết kế ra sao? |
| 6 | [`convention.md`](convention.md) | Coding / Naming Convention | Quy ước đặt mã định danh |
| — | [`../PLAN.md`](../PLAN.md) | **Roadmap** / Implementation Plan | Làm gì trước, làm gì sau, khi nào coi là xong? |

## Kiến thức (knowledge)

Sổ tay học tập, tách riêng khỏi tài liệu đặc tả ở trên: mỗi file giải thích **khái niệm và cú pháp** gặp khi làm một nhóm task, có sơ đồ, ví dụ code và bài tự kiểm tra. Ai mới vào repo, hoặc quên cú pháp, đọc ở đây.

| File | Nội dung | Liên quan |
|---|---|---|
| [`knowledge/Middleware.md`](knowledge/Middleware.md) | Middleware là gì, đọc từng dòng `CorrelationIdMiddleware`, từ điển cú pháp C# (so sánh C++), cú pháp test xUnit | Task 25 (M7) |
| [`knowledge/Commit.md`](knowledge/Commit.md) | Quy ước đặt tên commit (Conventional Commits), các loại và phạm vi, lệnh git thường dùng, cách sửa sai | Mọi task |

Quy ước: mỗi chủ đề một file trong `knowledge/`, đặt tên theo chủ đề, và thêm một dòng vào bảng trên.

**Đã biết lệch nhau:** `convention.md` ghi *mọi* ID đều là `NCHAR(10)` có tiền tố. Schema thực tế chỉ dùng kiểu này cho Customer / Employee / Branch; các bảng còn lại dùng `BIGINT IDENTITY`. Tin [`api_contract.md`](api_contract.md) §1.1 cho tới khi `convention.md` được sửa.
