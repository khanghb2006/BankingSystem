<#
    Banking System - Backend Run
    
    Run Spring Boot Backend (mvnw spring-boot:run)
    If port 8080 is already in use, automatically kill the process before running the backend.

    Usage:
        .\backend\run.ps1
#>
$ErrorActionPreference = "Stop"
$port = 8080

# -- Kill all process which is using port 8080
$old_process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue|
    Select-Object -ExpandProperty OwningProcess -Unique

if ($old_process) {
    Write-Host "Killing old process (PID $(old_process -join ', ' )) which is using port $port."-

    ForegroundColor Yellow
        $old_process | ForEach-Object {
            Stop-Process -Id $_ -Force
            -ErrorAction SilentlyContinue
        }
    Start-Sleep -Seconds 1
}

#-- Run backend
Write-Host "Starting backend on port $port..." -ForegroundColor Cyan
Push-Location $PSScriptRoot
try {
    .\mvnw spring-boot:run
}
finally {
    Pop-Location
}