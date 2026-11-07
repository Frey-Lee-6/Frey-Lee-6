@echo off
setlocal
cd /d "%~dp0"

where powershell >nul 2>nul
if errorlevel 1 (
  echo Windows PowerShell was not found.
  pause
  exit /b 1
)

echo Starting FX Desktop Widget...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$scriptPath = Join-Path '%~dp0' 'FxWidget.ps1'; $code = Get-Content -Raw -Encoding UTF8 $scriptPath; Invoke-Expression $code"
