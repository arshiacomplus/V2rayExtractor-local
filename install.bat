@echo off
setlocal enabledelayedexpansion

:: Configuration
set "REPO=arshiacomplus/V2rayExtractor-local"
set "CMD_NAME=v2l"
set "INSTALL_DIR=%APPDATA%\V2L_CLI"
set "LAUNCHER_PATH=%INSTALL_DIR%\%CMD_NAME%.exe"

:: Check if the executable is already installed
if exist "%LAUNCHER_PATH%" (
    echo V2L is already installed. Launching...
    start "" "%LAUNCHER_PATH%"
    exit /b 0
)

:: If not installed, proceed with installation
echo --- V2L First-Time Setup for Windows ---

:: --- Download and Extract ---
echo Fetching latest release from GitHub...
set "PS_CMD_GET_URL=powershell -NoProfile -ExecutionPolicy Bypass -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest').assets | Where-Object { $_.name -like '*windows-x64*' } | Select-Object -ExpandProperty browser_download_url""
for /f "delims=" %%i in ('%PS_CMD_GET_URL%') do set "DOWNLOAD_URL=%%i"

if not defined DOWNLOAD_URL (
    echo Error: Could not find a release asset for Windows.
    exit /b 1
)

echo Downloading release from %DOWNLOAD_URL%
set "ZIP_FILE=%TEMP%\v2l-asset.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'"

echo Extracting executable...
set "EXTRACT_DIR=%TEMP%\v2l-extracted"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

:: --- Installation ---
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo Installing to %INSTALL_DIR%...
for /f "delims=" %%f in ('dir /b /s "%EXTRACT_DIR%\v2ray_scraper_ui*.exe"') do (
    move "%%f" "%LAUNCHER_PATH%"
)

:: --- Add to PATH ---
echo Adding installation directory to your PATH...
setx PATH "%%PATH%%;%INSTALL_DIR%" >nul

:: --- Cleanup ---
del "%ZIP_FILE%"
rmdir /s /q "%EXTRACT_DIR%"

echo.
echo =================================================================
echo  Installation Successful!
echo.
echo  IMPORTANT: You MUST open a NEW terminal (CMD or PowerShell)
echo  for the new command to work.
echo.
echo  In the new terminal, you can run the application by typing:
echo    %CMD_NAME%
echo =================================================================

endlocal
