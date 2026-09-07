<#
======================================================
    Banking System - Clean Deploy / Smoke Test
    Description :
        Dung lai toan bo database tu con so 0 tren mot
        instance sach, theo dung thu tu phu thuoc.
        Chay xanh = ai clone repo ve cung dung duoc.

    Dung :
        # SQL Server Express (Windows auth)
        .\database\deploy.ps1
        .\database\deploy.ps1 -Seed
        .\database\deploy.ps1 -Server 'localhost\SQLEXPRESS' -Seed

        # Docker - chay 'docker compose up -d' truoc
        .\database\deploy.ps1 -Docker -Seed

    CANH BAO :
        Script XOA database BankingSystem tren -Server truoc khi dung lai.
        Chi tro vao instance dung de test, dung tro vao instance dang lam viec.
        -Seed chi dung khi test tay; deploy sach cho demo/CI thi bo qua.
======================================================
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

# -Docker = shortcut cho container trong docker-compose.yml
if ($Docker) {
    $Server   = 'localhost,1433'
    $User     = 'sa'
    $Password = 'BankSys_2026!'
}

# Connection args: Windows auth (-E) mac dinh, SQL auth khi truyen -User
$conn = @('-S', $Server, '-C')
if ($User) { $conn += @('-U', $User, '-P', $Password) } else { $conn += '-E' }

function Invoke-SqlFile($path) {
    Write-Host ">> $($path.Substring($root.Length + 1))"
    sqlcmd @conn -b -i $path
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "DEPLOY FAILED tai: $($path.Substring($root.Length + 1))" -ForegroundColor Red
        exit 1
    }
}

$modules = @(
    'account', 'bank_transaction', 'banking_account', 'beneficiary', 'branch',
    'card', 'customer', 'employee', 'loan', 'login_history', 'notification',
    'otp', 'saving_account'
)

Write-Host "Target : $Server" -ForegroundColor Cyan

# Doi SQL Server san sang (container moi khoi dong mat ~15s)
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    sqlcmd @conn -Q "SELECT 1" *> $null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep 2
}
if (-not $ready) {
    Write-Host "SQL Server khong phan hoi tai $Server" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 0. Xoa DB cu de dung lai tu dau
sqlcmd @conn -b -Q @"
IF DB_ID('BankingSystem') IS NOT NULL
BEGIN
    ALTER DATABASE BankingSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankingSystem;
END
"@
if ($LASTEXITCODE -ne 0) { exit 1 }

# 1. Schema - thu tu bat buoc
foreach ($f in 'schema', 'lookup', 'constraints', 'defaults', 'indexes', 'sequences') {
    Invoke-SqlFile (Join-Path $src "schema\$f.sql")
}
Invoke-SqlFile (Join-Path $src 'schema\seeds\lookup.sql')

# 2. Helper functions dung chung (mask, luhn, ...)
Get-ChildItem "$src\common\*.sql" | ForEach-Object { Invoke-SqlFile $_.FullName }

# 3. Validate functions cua tung module
foreach ($m in $modules) {
    Get-ChildItem "$src\$m\utils\*.sql" -ErrorAction SilentlyContinue |
        ForEach-Object { Invoke-SqlFile $_.FullName }
}

# 4. Views - can helper functions o buoc 2
Get-ChildItem "$src\view\*.sql" | ForEach-Object { Invoke-SqlFile $_.FullName }

# 5. Procedures - can views va validate functions
foreach ($m in $modules) {
    Get-ChildItem "$src\$m\*.sql", "$src\$m\*\*.sql" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike '*\utils\*' } |
        ForEach-Object { Invoke-SqlFile $_.FullName }
}

Write-Host ""
Write-Host "DEPLOY OK" -ForegroundColor Green

# 6. Seed data test (chi khi -Seed) - chay sau cung, DB da co du proc
if ($Seed) {
    Write-Host ""
    Invoke-SqlFile (Join-Path $src 'schema\seeds\seed.sql')
    Write-Host ""
    Write-Host "SEED OK" -ForegroundColor Green
}
