
$VHDLocations = "\\avdfxlogix3.file.core.windows.net\newprofiles\users"
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name Enabled -PropertyType dword -Value 1 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType dword -Value 1 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name FlipFlopProfileDirectoryName -PropertyType dword -Value 1 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name LockedRetryCount -PropertyType dword -Value 3 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name LockedRetryInterval -PropertyType dword -Value 15 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name ProfileType -PropertyType dword -Value 0 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name ReAttachIntervalSeconds -PropertyType dword -Value 15 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name ReAttachRetryCount -PropertyType dword -Value 3 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name SizeInMBs -PropertyType dword -Value 30000 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name VHDLocations -PropertyType string -value $VHDLocations -Force
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles\ -Name VolumeType -PropertyType string -Value vhdx -Force




# Enable Cloud Kerberos ticket retrieval (equivalent to the GPO / CSP)
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos" -Name "Parameters" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters" `
  -Name "CloudKerberosTicketRetrievalEnabled" -PropertyType DWord -Value 1 -Force | Out-Null

# Ensure Credential Manager keys are taken from the currently loading profile (FSLogix roaming)
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "AzureADAccount" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\AzureADAccount" `
  -Name "LoadCredKeyFromProfile" -PropertyType DWord -Value 1 -Force | Out-Null

# Map .file.core.windows.net to the Entra ID Kerberos realm
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\HostToRealm\KERBEROS.MICROSOFTONLINE.COM" -Force | Out-Null

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\HostToRealm\KERBEROS.MICROSOFTONLINE.COM" `
    -Name "SpnMappings" `
    -PropertyType MultiString `
    -Value ".file.core.windows.net" `
    -Force | Out-Null

Write-Host "Entra Kerberos enabled and Credential Manager profile binding configured."

write-host "Configuration Complete"


# ----------------- CONFIGURE THESE -----------------
$InstallerUrl  = "https://sophielex.eastus2.cloudapp.azure.com/updates/SophieLex-latest-windows.exe"  # public URL or SAS link
$InstallerName = "SophieLex-latest-windows.exe"                                                       # local filename to save as
$SilentArgs    = "/S /allusers /D=c:\program files\SophieLex"                                       # see framework notes above
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
