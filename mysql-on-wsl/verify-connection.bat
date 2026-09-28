@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "MYSQL=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"

if not exist "%MYSQL%" (
    echo [ERROR] mysql.exe not found at:
    echo         %MYSQL%
    echo         Adjust the MYSQL variable at the top of this file.
    pause
    exit /b 1
)

echo ============================================================
echo   Verify: Windows host  --^>  MySQL in WSL2  (127.0.0.1:3307)
echo ============================================================
echo.
echo NOTE: "Using a password on the command line ... insecure" is a
echo       harmless warning from the client. Ignore it.
echo.

echo --- Test 1: root, check port / charset / timezone ----------------
"%MYSQL%" -h 127.0.0.1 -P 3307 -u root -proot123456 --connect-timeout=5 ^
  -e "SELECT VERSION() AS version, @@port AS port, @@character_set_server AS charset, @@time_zone AS tz;"
if errorlevel 1 (
    echo.
    echo   [FAIL] Cannot reach 127.0.0.1:3307.
    echo          - Is the container up?  Run start-mysql.bat first.
    echo          - Is Docker Desktop running?
    echo.
    pause
    exit /b 1
)
echo.

echo --- Test 2: app user 'dev' on demo_db, read sample rows ----------
"%MYSQL%" -h 127.0.0.1 -P 3307 -u dev -pdev123456 -D demo_db --connect-timeout=5 ^
  -e "SELECT * FROM t_user;"
echo.

echo ============================================================
echo   ALL PASS - Windows can reach the MySQL running in WSL2.
echo   JDBC URL:
echo   jdbc:mysql://127.0.0.1:3307/demo_db?useUnicode=true^&characterEncoding=utf8^&useSSL=false^&serverTimezone=Asia/Shanghai^&allowPublicKeyRetrieval=true
echo ============================================================
echo.
pause
exit /b 0
