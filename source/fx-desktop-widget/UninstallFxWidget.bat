@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -Command "$desktop = [Environment]::GetFolderPath('Desktop'); $shortcutPath = Join-Path $desktop 'FX Desktop Widget.lnk'; if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }; $appDir = Join-Path $env:LOCALAPPDATA 'FxDesktopWidget'; if (Test-Path $appDir) { Remove-Item $appDir -Recurse -Force }"

echo.
echo Uninstalled.
pause
