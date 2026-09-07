<#
======================================================
    Banking System - Nap data test (seed.sql)
    Chi chay duoc 1 lan sau moi deploy (seed.sql khong idempotent).
    Muon seed lai tu dau: .\database\deploy.ps1 -Seed

    Dung :
        .\database\seed.ps1
        .\database\seed.ps1 -Server 'localhost\SQLEXPRESS'
        .\database\seed.ps1 -Docker
======================================================
#>
param(
    [string]$Server = 'localhost\SQLEXPRESS01',
    [string]$User,
    [string]$Password,
    [switch]$Docker
)

if ($Docker) {
    $Server   = 'localhost,1433'
    $User     = 'sa'
    $Password = 'BankSys_2026!'
}

$conn = @('-S', $Server, '-C')
if ($User) { $conn += @('-U', $User, '-P', $Password) } else { $conn += '-E' }
$seed = Join-Path $PSScriptRoot 'src\schema\seeds\seed.sql'

Write-Host "Seed -> $Server" -ForegroundColor Cyan
sqlcmd @conn -b -i $seed

if ($LASTEXITCODE -eq 0) {
    Write-Host "SEED OK" -ForegroundColor Green
} else {
    Write-Host "SEED FAILED" -ForegroundColor Red
    exit 1
}
