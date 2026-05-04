@echo off
chcp 65001 >nul
title Jin Yong Chat Upload
color 0E

echo ============================================
echo     Jin Yong Chat - Upload to Server
echo ============================================
echo.

REM ===== CONFIG =====
set SERVER_IP=SERVER_IP
set SSH_USER=ubuntu
set SSH_PORT=22
set REMOTE_PATH=/var/www/html/jin-yong-chat
set LOCAL_PATH=%~dp0
REM ==================

echo Current config:
echo   Server: %SSH_USER%@%SERVER_IP%:%SSH_PORT%
echo   Target: %REMOTE_PATH%
echo   Local:  %LOCAL_PATH%
echo.

REM Check ssh
where ssh >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ssh not found!
    pause
    exit /b 1
)

REM Check scp
where scp >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: scp not found!
    pause
    exit /b 1
)

echo Testing SSH connection...
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p %SSH_PORT% %SSH_USER%@%SERVER_IP% "echo OK" < nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo SSH connection failed!
    pause
    exit /b 1
)

echo SSH connection OK!
echo.

REM ===== Step 1: Create directory and open permissions =====
echo Step 1: Preparing directory...
ssh -t -p %SSH_PORT% %SSH_USER%@%SERVER_IP% "sudo rm -rf %REMOTE_PATH% && sudo mkdir -p %REMOTE_PATH% && sudo chmod 777 %REMOTE_PATH% && echo DONE"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create directory!
    pause
    exit /b 1
)
echo Directory ready!
echo.

REM ===== Step 2: Upload files =====
echo Step 2: Uploading files...
echo.

scp -P %SSH_PORT% -o StrictHostKeyChecking=no ^
    "%LOCAL_PATH%index.html" ^
    "%LOCAL_PATH%server.js" ^
    "%LOCAL_PATH%.env" ^
    "%LOCAL_PATH%.gitignore" ^
    "%LOCAL_PATH%README.md" ^
    "%LOCAL_PATH%deploy.sh" ^
    "%SSH_USER%@%SERVER_IP%:%REMOTE_PATH%/"

if %ERRORLEVEL% NEQ 0 (
    echo Upload failed!
    pause
    exit /b 1
)

echo All files uploaded!
echo.

REM ===== Step 3: Secure permissions =====
echo Step 3: Securing permissions...
ssh -t -p %SSH_PORT% %SSH_USER%@%SERVER_IP% "sudo chmod 755 %REMOTE_PATH% && sudo chmod 600 %REMOTE_PATH%/.env && sudo chown -R %SSH_USER%:%SSH_USER% %REMOTE_PATH% && ls -la %REMOTE_PATH%"
echo.

REM ===== Step 4: Install dependencies =====
echo Step 4: Installing npm dependencies...
ssh -t -p %SSH_PORT% %SSH_USER%@%SERVER_IP% "cd %REMOTE_PATH% && npm init -y 2>/dev/null && npm install express cors dotenv"
if %ERRORLEVEL% NEQ 0 (
    echo npm install failed!
    pause
    exit /b 1
)
echo.

REM ===== Step 5: Start server =====
echo Step 5: Starting server on port 8079...
echo.
echo Access via: http://%SERVER_IP%:8079
echo.

ssh -t -p %SSH_PORT% %SSH_USER%@%SERVER_IP% "cd %REMOTE_PATH% && (pm2 delete jin-yong-chat 2>/dev/null || true) && pm2 start server.js --name jin-yong-chat && pm2 save"

echo.
echo ============================================
echo     Done!
echo ============================================
echo.
echo   Access: http://%SERVER_IP%:8079
echo.
echo   Commands:
echo     pm2 status              - check status
echo     pm2 logs jin-yong-chat  - view logs
echo     pm2 restart jin-yong-chat - restart
echo.
pause
