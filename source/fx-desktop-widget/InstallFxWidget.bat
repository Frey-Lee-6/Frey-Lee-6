@echo off
setlocal

set "APPDIR=%LOCALAPPDATA%\FxDesktopWidget"
set "SRCDIR=%~dp0"

where powershell >nul 2>nul
if errorlevel 1 (
  echo Windows PowerShell was not found.
  pause
  exit /b 1
)

if not exist "%APPDIR%" mkdir "%APPDIR%"
copy /Y "%SRCDIR%FxWidget.ps1" "%APPDIR%\FxWidget.ps1" >nul
copy /Y "%SRCDIR%RunFxWidget.vbs" "%APPDIR%\RunFxWidget.vbs" >nul

powershell -NoProfile -ExecutionPolicy Bypass -Command "$desktop = [Environment]::GetFolderPath('Desktop'); $shortcutPath = Join-Path $desktop 'FX Desktop Widget.lnk'; $target = Join-Path $env:WINDIR 'System32\wscript.exe'; $args = '"""' + (Join-Path $env:LOCALAPPDATA 'FxDesktopWidget\RunFxWidget.vbs') + '"""'; $shell = New-Object -ComObject WScript.Shell; $shortcut = $shell.CreateShortcut($shortcutPath); $shortcut.TargetPath = $target; $shortcut.Arguments = $args; $shortcut.WorkingDirectory = Join-Path $env:LOCALAPPDATA 'FxDesktopWidget'; $shortcut.IconLocation = 'shell32.dll,44'; $shortcut.Save()"

echo.
echo Installed. A desktop shortcut named "FX Desktop Widget" has been created.
echo You can send this folder to others; they only need to run InstallFxWidget.bat.
pause
