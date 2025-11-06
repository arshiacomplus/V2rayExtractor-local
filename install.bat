@echo off
setlocal

:: Configuration
set "REPO=arshiacomplus/V2rayExtractor-local"
set "CMD_NAME=v2l"
set "ASSET_KEYWORD=windows-x64"

echo Starting installation for V2L (V2rayExtractor-local)...

:: --- Get Latest Release Download URL using PowerShell ---
echo Fetching latest release from GitHub...
set "PS_CMD_GET_URL=powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest').assets | Where-Object { $_.name -like '*%ASSET_KEYWORD%*' } | Select-Object -ExpandProperty browser_download_url""

for /f "delims=" %%i in ('%PS_CMD_GET_URL%') do set "DOWNLOAD_URL=%%i"

if not defined DOWNLOAD_URL (
    echo Error: Could not find a release asset for Windows. Please check the releases page.
    exit /b 1
)

echo Found download URL: %DOWNLOAD_URL%

:: --- Download and Extract ---
echo Downloading release...
set "ZIP_FILE=%TEMP%\v2l-asset.zip"
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'"

echo Extracting files...
set "EXTRACT_DIR=%TEMP%\v2l-extracted"
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

:: --- Installation ---
:: Create a permanent directory for the executable
set "INSTALL_DIR=%APPDATA%\V2L_CLI"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Installing '%CMD_NAME%.exe' to %INSTALL_DIR%...
:: Find and move the executable
for /f "delims=" %%f in ('dir /b /s "%EXTRACT_DIR%\v2ray_scraper_ui*.exe"') do (
    move "%%f" "%INSTALL_DIR%\%CMD_NAME%.exe"
)

:: --- Add directory to user's PATH ---
echo Adding installation directory to your PATH...
:: We check if the path is already added to avoid duplicates
echo %PATH% | find "%INSTALL_DIR%" >nul
if errorlevel 1 (
    setx PATH "%%PATH%%;%INSTALL_DIR%"
) else (
    echo Directory is already in your PATH.
)

:: --- Cleanup ---
del "%ZIP_FILE%"
rmdir /s /q "%EXTRACT_DIR%"

echo.
echo =================================================================
echo  Installation Successful!
echo.
echo  To start using the command, you MUST open a NEW terminal
echo  (Command Prompt, PowerShell, or Windows Terminal).
echo.
echo  Then, you can run the application by simply typing:
echo    %CMD_NAME%
echo =================================================================

endlocal