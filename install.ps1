# =================================================================
# V2L - Advanced Smart Installer & Updater for Windows (PowerShell Version)
# Created by arshiacomplus
# =================================================================

# --- Configuration ---
$Repo = "arshiacomplus/V2rayExtractor-local"
$CmdName = "v2l"
$InstallDir = Join-Path $env:APPDATA "V2L_CLI"
$LauncherPath = Join-Path $InstallDir "$CmdName.exe"
$AppV = "1.0.0"
$CoreV = "1.1"
$AppVersionFile = Join-Path $InstallDir ".app_version"
$CoreVersionFile = Join-Path $InstallDir ".core_version"

# --- Main Logic ---
try {
    # Check for existing installation
    if (Test-Path $LauncherPath) {
        $InstalledAppV = if (Test-Path $AppVersionFile) { Get-Content $AppVersionFile } else { "0" }
        $InstalledCoreV = if (Test-Path $CoreVersionFile) { Get-Content $CoreVersionFile } else { "0" }

        if ($InstalledAppV -eq $AppV -and $InstalledCoreV -eq $CoreV) {
            Write-Host "V2L is already up-to-date (App: v$AppV, Core: v$CoreV). Launching..." -ForegroundColor Green
            Start-Process $LauncherPath
            # Use Start-Sleep to give the user time to see the message before the window closes
            Start-Sleep -Seconds 3
            exit 0
        }

        Write-Host "A new version is required. Updating..." -ForegroundColor Yellow
        Write-Host "Deleting old installation for a clean update..." -ForegroundColor Yellow
        Remove-Item -Path $InstallDir -Recurse -Force
    }

    Write-Host "--- V2L First-Time Setup / Update for Windows ---" -ForegroundColor Cyan

    Write-Host "Fetching latest release from GitHub..."
    # Ensure TLS 1.2 is used for GitHub API calls
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    $release = Invoke-RestMethod -Uri $apiUrl
    $asset = $release.assets | Where-Object { $_.name -like '*windows-x64*' }

    if (-not $asset) {
        throw "Could not find a release asset for Windows."
    }

    $DownloadUrl = $asset.browser_download_url
    Write-Host "Downloading release from $DownloadUrl"

    $ZipFile = Join-Path $env:TEMP "v2l-asset.zip"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile

    Write-Host "Extracting executable..."
    $ExtractDir = Join-Path $env:TEMP "v2l-extracted"
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

    if (-not (Test-Path $InstallDir)) {
        New-Item -Path $InstallDir -ItemType Directory | Out-Null
    }

    Write-Host "Installing to $InstallDir..."
    $exeFile = Get-ChildItem -Path $ExtractDir -Recurse -Filter "*.exe" | Select-Object -First 1
    if (-not $exeFile) {
        throw "Could not find the main executable in the downloaded archive."
    }

    Move-Item -Path $exeFile.FullName -Destination $LauncherPath

    # Save new version files
    Set-Content -Path $AppVersionFile -Value $AppV
    Set-Content -Path $CoreVersionFile -Value $CoreV

    Write-Host "Adding installation directory to your PATH..."
    # Get current user PATH
    $CurrentUserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($CurrentUserPath -notlike "*$InstallDir*") {
        Write-Host "Adding new path to environment variables..."
        $NewPath = $CurrentUserPath + ";" + $InstallDir
        [System.Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    } else {
        Write-Host "Path is already set." -ForegroundColor Blue
    }

    # --- Cleanup ---
    Remove-Item -Path $ZipFile -Force
    Remove-Item -Path $ExtractDir -Recurse -Force

    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host " Installation/Update Successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host " IMPORTANT: You MUST open a NEW terminal for the new command to work." -ForegroundColor Yellow
    Write-Host ""
    Write-Host " In the new terminal, you can run the application by typing: $CmdName" -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Installation failed." -ForegroundColor Red
}
finally {
    # Pause at the end
    Write-Host ""
    Read-Host "Press Enter to exit..."
}