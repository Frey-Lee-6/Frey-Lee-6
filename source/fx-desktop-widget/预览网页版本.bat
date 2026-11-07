@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo 未检测到 Python，无法启动本地预览服务。
  pause
  exit /b 1
)

echo 浏览器访问地址: http://127.0.0.1:4173/index.html
echo 关闭本窗口即可停止预览服务。
python -m http.server 4173 --bind 127.0.0.1
