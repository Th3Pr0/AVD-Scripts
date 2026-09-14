<#
.SYNOPSIS
    Downloads and silently installs a custom EXE-based application.
    Intended for use as a PowerShell customizer step in an Azure Image Builder
    template (e.g. Azure Virtual Desktop "Custom image templates").

.DESCRIPTION
    - Downloads the installer from a public URL (GitHub raw link, Azure Blob + SAS, etc.)
    - Runs it with a silent/unattended switch
    - Logs progress and exit codes so they show up in AIB's customization.log
    - Cleans up the downloaded installer afterward

.NOTES
    Host this file at a public URL and reference it as a "PowerShell script"
    customizer step in your image template, or paste its contents into an
    "inline" PowerShell customizer.

    If the installer can return exit code 3010 (reboot required), add a
    "WindowsRestart" customizer step immediately after this one in your template.

    PICKING THE RIGHT SilentArgs VALUE (varies by installer framework):
      - NSIS-based:            /S
      - Inno Setup-based:      /VERYSILENT /NORESTART /SUPPRESSMSGBOXES
      - InstallShield-based:   /s /v"/qn"
      - WiX Burn bootstrapper: /quiet /norestart
      If you're not sure which one your installer uses, try running
      "YourApp-Setup.exe /?" or "/help" locally first, or check the vendor's
      silent-install documentation.
#>

# ----------------- CONFIGURE THESE -----------------
$InstallerUrl  = "https://sophielex.eastus2.cloudapp.azure.com/updates/SophieLex-latest-windows.exe"    # public URL or SAS link
$InstallerName = "SophieLex-latest-windows.exe"                                                         # local filename to save as
$SilentArgs    = "/S /allusers /D=c:\program files\SophieLex"                                           # see framework notes above
# -----------------------------------------------------

$WorkDir       = "C:\AIBCustomizations"
$InstallerPath = Join-Path $WorkDir $InstallerName

Write-Output "=== Starting custom app install: $InstallerName ==="

# 1. Prepare working directory
if (-not (Test-Path $WorkDir)) {
    New-Item -Path $WorkDir -ItemType Directory -Force | Out-Null
}

# 2. Download the installer
try {
    Write-Output "Downloading installer from $InstallerUrl ..."
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing
    Write-Output "Download complete: $InstallerPath"
}
catch {
    Write-Error "Failed to download installer: $_"
    exit 1
}

# 3. Run the silent install
try {
    Write-Output "Running installer with args: $SilentArgs"
    $process  = Start-Process -FilePath $InstallerPath -ArgumentList $SilentArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
    Write-Output "Installer exited with code $exitCode"

    if ($exitCode -eq 0) {
        Write-Output "Install succeeded."
    }
    elseif ($exitCode -eq 3010) {
        Write-Output "Install succeeded but requires a reboot (exit code 3010)."
        # Add a WindowsRestart customizer step right after this one in your AIB template.
    }
    else {
        Write-Error "Installer returned non-success exit code: $exitCode"
        exit $exitCode
    }
}
catch {
    Write-Error "Failed to run installer: $_"
    exit 1
}

# 4. Clean up the installer so it doesn't bloat the final image
try {
    Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue
    Write-Output "Cleaned up installer file."
}
catch {
    Write-Warning "Could not remove installer file: $_"
}

Write-Output "=== Custom app install complete ==="
