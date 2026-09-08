

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

