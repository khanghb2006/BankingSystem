## ID Naming Convention

All primary keys in the Banking System follow a fixed-length identifier format to ensure consistency, readability, and easier maintenance.

| Entity | Prefix | Format | Example | Length |
|---------|:------:|--------|---------|:------:|
| Customer (CIF) | CIF | `CIF` + 7 digits | `CIF0000001` | 10 |
| Employee | EMP | `EMP` + 7 digits | `EMP0000001` | 10 |
| Branch | BR | `BR` + 8 digits | `BR00000001` | 10 |
| Account | AC | `AC` + 8 digits | `AC00000001` | 10 |
| Card | CA | `CA` + 8 digits | `CA00000001` | 10 |
| Bank Transaction | TR | `TR` + 8 digits | `TR00000001` | 10 |
| Loan | LO | `LO` + 8 digits | `LO00000001` | 10 |
| Savings Account | SA | `SA` + 8 digits | `SA00000001` | 10 |
| Beneficiary | BE | `BE` + 8 digits | `BE00000001` | 10 |
| Notification | NO | `NO` + 8 digits | `NO00000001` | 10 |
| OTP | OT | `OT` + 8 digits | `OT00000001` | 10 |
| Login History | LG | `LG` + 8 digits | `LG00000001` | 10 |

### Notes

- All IDs are stored as **NCHAR(10)**.
- IDs are generated using **SQL Server SEQUENCE** objects.
- Numeric portions are left-padded with zeros to maintain a fixed length.
- **Customer IDs use the `CIF` prefix (Customer Information File)**, following common banking industry conventions.
- IDs are immutable and never reused, even if a record is deleted.