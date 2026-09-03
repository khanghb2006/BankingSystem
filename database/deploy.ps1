<#
======================================================
    Banking System - Clean Deploy / Smoke Test
    Description :
        Dung lai toan bo database tu con so 0 tren mot
        instance sach, theo dung thu tu phu thuoc.
        Chay xanh = ai clone repo ve cung dung duoc.

    Dung :
        .\database\deploy.ps1
        .\database\deploy.ps1 -Server 'localhost\SQLEXPRESS01'

    CANH BAO :
        Script XOA database BankingSystem tren -Server
        truoc khi dung lai. Chi tro vao instance dung
        de test, dung tro vao instance dang lam viec.
======================================================
#>
param(
    [string]$Server = 'localhost\SQLEXPRESS01'
)

$ErrorActionPreference = 'Stop'
$src  = Join-Path $PSScriptRoot 'src'
$root = Split-Path $PSScriptRoot -Parent

function Invoke-SqlFile($path) {
    Write-Host ">> $($path.Substring($root.Length + 1))"
    sqlcmd -S $Server -E -C -b -i $path
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
Write-Host ""

# 0. Xoa DB cu de dung lai tu dau
sqlcmd -S $Server -E -C -b -Q @"
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
