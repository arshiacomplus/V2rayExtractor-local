@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: V2L - Advanced Smart Installer & Updater for Windows
:: Created by arshiacomplus
:: =================================================================

:: --- Configuration ---
set "REPO=arshiacomplus/V2rayExtractor-local"
set "CMD_NAME=v2l"
set "INSTALL_DIR=%APPDATA%\V2L_CLI"
set "LAUNCHER_PATH=%INSTALL_DIR%\%CMD_NAME%.exe"
set "APP_V=1.0.0"
set "CORE_V=1.1"
set "APP_VERSION_FILE=%INSTALL_DIR%\.app_version"
set "CORE_VERSION_FILE=%INSTALL_DIR%\.core_version"

:: --- Main Logic ---
if exist "%LAUNCHER_PATH%" (
    if exist "%APP_VERSION_FILE%" (
        set /p INSTALLED_APP_V=<"%APP_VERSION_FILE%"
    ) else (
        set "INSTALLED_APP_V=0"
    )

    if exist "%CORE_VERSION_FILE%" (
        set /p INSTALLED_CORE_V=<"%CORE_VERSION_FILE%"
    ) else (
        set "INSTALLED_CORE_V=0"
    )

    if "!INSTALLED_APP_V!" == "!APP_V!" (
        if "!INSTALLED_CORE_V!" == "!CORE_V!" (
            echo V2L is already up-to-date (App: v!APP_V!, Core: v!CORE_V!). Launching...
            start "" "%LAUNCHER_PATH%"
            exit /b 0
        )
    )

    echo A new version is required. Updating...
    echo Deleting old installation for a clean update...
    rmdir /s /q "%INSTALL_DIR%"
)

echo --- V2L First-Time Setup / Update for Windows ---

echo Fetching latest release from GitHub...
set "URL_FILE=%TEMP%\v2l_download_url.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$url = (Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest').assets | Where-Object { $_.name -like '*windows-x64*' } | Select-Object -ExpandProperty browser_download_url; Set-Content -Path '%URL_FILE%' -Value $url"

if not exist "%URL_FILE%" (
    echo Error: Could not retrieve download URL.
    pause
    exit /b 1
)

set /p DOWNLOAD_URL=<%URL_FILE%
del "%URL_FILE%"

if not defined DOWNLOAD_URL (
    echo Error: Could not find a release asset for Windows.
    pause
    exit /b 1
)

echo Downloading release from %DOWNLOAD_URL%
set "ZIP_FILE=%TEMP%\v2l-asset.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'"

echo Extracting executable...
set "EXTRACT_DIR=%TEMP%\v2l-extracted"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo Installing to %INSTALL_DIR%...
for /f "delims=" %%f in ('dir /b /s "%EXTRACT_DIR%\v2ray_scraper_ui*.exe"') do (
    move "%%f" "%LAUNCHER_PATH%"
)

:: Save new version files
echo %APP_V% > "%APP_VERSION_FILE%"
echo %CORE_V% > "%CORE_VERSION_FILE%"

echo Adding installation directory to your PATH...
echo %PATH% | find "%INSTALL_DIR%" >nul
if errorlevel 1 (
    echo Adding new path to environment variables...
    setx PATH "%%PATH%%;%INSTALL_DIR%"
)

del "%ZIP_FILE%"
rmdir /s /q "%EXTRACT_DIR%"

echo.
echo =================================================================
echo  Installation/Update Successful!
echo.
echo  IMPORTANT: You MUST open a NEW terminal for the new command to work.
echo.
echo  In the new terminal, you can run the application by typing: %CMD_NAME%
echo =================================================================
pause
endlocal
