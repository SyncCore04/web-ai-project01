@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo   Start MySQL on WSL2 (Docker Desktop)   host port 3307
echo ============================================================
echo.

echo [1/3] Checking Docker engine ...
docker version --format "{{.Server.Version}}" >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [ERROR] Docker engine is NOT running.
    echo           Open Docker Desktop, wait for "Engine running", then retry.
    echo.
    pause
    exit /b 1
)
echo       OK - Docker engine is up.
echo.

echo [2/3] docker compose up -d ...
docker compose up -d
if errorlevel 1 (
    echo.
    echo   [ERROR] docker compose up failed. See output above.
    echo.
    pause
    exit /b 1
)
echo.

echo [3/3] Waiting for MySQL to become healthy (max ~90s) ...
set /a tries=0
:waitloop
set /a tries+=1
for /f "delims=" %%s in ('docker inspect -f "{{.State.Health.Status}}" mysql-wsl 2^>nul') do set STATUS=%%s
if "%STATUS%"=="healthy" goto ready
if %tries% GEQ 30 goto timeout
timeout /t 3 /nobreak >nul
goto waitloop

:ready
echo       OK - MySQL is healthy.
echo.
docker compose ps
echo.
echo ------------------------------------------------------------
echo   Host  : 127.0.0.1 : 3307
echo   root  : root123456
echo   app   : dev / dev123456   database: demo_db
echo ------------------------------------------------------------
echo.
echo   Verify from Windows:  double-click verify-connection.bat
echo   Open a shell        :  docker exec -it mysql-wsl mysql -uroot -proot123456
echo.
pause
exit /b 0

:timeout
echo.
echo   [WARN] Not healthy after ~90s. Check logs:
echo          docker compose logs --tail=80 mysql
echo.
pause
exit /b 1
