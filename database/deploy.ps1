<#
======================================================================
    Banking System - Clean Deploy

    Dung lai toan bo database BankingSystem tu con so 0, theo dung thu
    tu phu thuoc. Chay xanh = ai clone repo ve deploy cung dung duoc.

    CACH DUNG
        # SQL Server Express - Windows auth (mac dinh)
        .\database\deploy.ps1
        .\database\deploy.ps1 -Seed
        .\database\deploy.ps1 -Server 'localhost\SQLEXPRESS'

        # SQL auth
        .\database\deploy.ps1 -Server 'localhost,1433' -User sa -Password '***'

        # Docker (chay 'docker compose up -d' truoc)
        .\database\deploy.ps1 -Docker -Seed

    THAM SO
        -Server    Instance dich. Mac dinh localhost\SQLEXPRESS01.
        -User/-Password  Dung SQL auth thay vi Windows auth.
        -Docker    Shortcut: Server=localhost,1433 + sa + mat khau trong docker-compose.yml.
        -Seed      Sau khi deploy, nap them schema\seeds\seed.sql (demo data).

    CANH BAO
        Script XOA database BankingSystem tren -Server truoc khi dung lai.
        Chi tro vao instance de test.

    LUU Y
        Stored procedure co deferred name resolution -> "DEPLOY OK" chi
        chung minh moi object CREATE duoc, KHONG chung minh proc chay dung.
        Chay -Seed (hoac integration test) de kiem tra runtime.
======================================================================
#>
param(
    [string]$Server = 'localhost\SQLEXPRESS01',
    [string]$User,
    [string]$Password,
    [switch]$Docker,
    [switch]$Seed
)

$ErrorActionPreference = 'Stop'
$src  = Join-Path $PSScriptRoot 'src'
$root = Split-Path $PSScriptRoot -Parent

# Danh sach module (dung cho buoc validate-functions va procedures)
$modules = @(
    'account', 'bank_transaction', 'banking_account', 'beneficiary', 'branch',
    'card', 'customer', 'employee', 'loan', 'login_history', 'notification',
    'otp', 'saving_account'
)

# --- Ket noi ---------------------------------------------------------
if ($Docker) {
    $Server   = 'localhost,1433'
    $User     = 'sa'
    $Password = 'BankSys_2026!'
}
$conn = @('-S', $Server, '-C')
if ($User) { $conn += @('-U', $User, '-P', $Password) } else { $conn += '-E' }

# --- Helpers --------------------------------------------------------
function Assert-Ok($message) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host $message -ForegroundColor Red
        exit 1
    }
}

function Invoke-SqlFile($path) {
    Write-Host ">> $($path.Substring($root.Length + 1))"
    sqlcmd @conn -b -i $path
    Assert-Ok "DEPLOY FAILED tai: $($path.Substring($root.Length + 1))"
}

# --- Preflight ------------------------------------------------------
if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Host "Khong tim thay 'sqlcmd' tren PATH. Cai 'SQL Server Command Line Utilities' roi mo lai terminal." -ForegroundColor Red
    exit 1
}

Write-Host "Target : $Server" -ForegroundColor Cyan

# Doi SQL Server san sang (container moi khoi dong mat ~15s)
for ($i = 0; $i -lt 30; $i++) {
    sqlcmd @conn -Q "SELECT 1" *> $null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep 2
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "SQL Server khong phan hoi tai $Server" -ForegroundColor Red
    exit 1
}
Write-Host ""

# --- 0. Xoa DB cu --------------------------------------------------
Write-Host ">> DROP DATABASE BankingSystem (neu ton tai)"
sqlcmd @conn -b -Q @"
IF DB_ID('BankingSystem') IS NOT NULL
BEGIN
    ALTER DATABASE BankingSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankingSystem;
END
"@
Assert-Ok "Khong xoa duoc DB cu (quyen sysadmin? con connection dang mo tren BankingSystem?)."

# --- 1. Schema (thu tu bat buoc) ---------------------------------
foreach ($f in 'schema', 'lookup', 'constraints', 'defaults', 'indexes', 'sequences') {
    Invoke-SqlFile (Join-Path $src "schema\$f.sql")
}
Invoke-SqlFile (Join-Path $src 'schema\seeds\lookup.sql')

# --- 2. Helper functions dung chung (mask, luhn, ...) -----------
Get-ChildItem "$src\common\*.sql" | Sort-Object FullName |
    ForEach-Object { Invoke-SqlFile $_.FullName }

# --- 3. Validate functions cua tung module ---------------------
foreach ($m in $modules) {
    Get-ChildItem "$src\$m\utils\*.sql" -ErrorAction SilentlyContinue | Sort-Object FullName |
        ForEach-Object { Invoke-SqlFile $_.FullName }
}

# --- 4. Views (can helper functions o buoc 2) -----------------
Get-ChildItem "$src\view\*.sql" | Sort-Object FullName |
    ForEach-Object { Invoke-SqlFile $_.FullName }

# --- 5. Procedures (can views + validate functions; -Recurse, bo qua utils) --
foreach ($m in $modules) {
    Get-ChildItem "$src\$m" -Recurse -Filter *.sql -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike '*\utils\*' } |
        Sort-Object FullName |
        ForEach-Object { Invoke-SqlFile $_.FullName }
}

# --- 6. Kiem chung: dem object da tao -------------------------
Write-Host ""
Write-Host "-- Kiem chung --" -ForegroundColor Cyan
sqlcmd @conn -b -d BankingSystem -Q @"
SET NOCOUNT ON;
SELECT
    (SELECT COUNT(*) FROM sys.tables)                                  AS [tables],
    (SELECT COUNT(*) FROM sys.views)                                   AS [views],
    (SELECT COUNT(*) FROM sys.objects WHERE type = 'P')                AS [procedures],
    (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF'))  AS [functions];
"@
Assert-Ok "Khong doc duoc so object sau deploy."

Write-Host ""
Write-Host "DEPLOY OK" -ForegroundColor Green

# --- 7. Seed demo data (chi khi -Seed) ----------------------
if ($Seed) {
    Write-Host ""
    Invoke-SqlFile (Join-Path $src 'schema\seeds\seed.sql')
    Write-Host ""
    Write-Host "SEED OK" -ForegroundColor Green
}
