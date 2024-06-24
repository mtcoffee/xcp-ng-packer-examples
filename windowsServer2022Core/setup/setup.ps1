$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Switch network connection to private mode
# Required for WinRM firewall rules
$profile = Get-NetConnectionProfile
Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private

# Enable WinRM service
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

#install cloudbase-init
$msiLocation = 'https://cloudbase.it/downloads'
$msiFileName = 'CloudbaseInitSetup_Stable_x64.msi'
Invoke-WebRequest -Uri ($msiLocation + '/' + $msiFileName) -OutFile C:\$msiFileName
Unblock-File -Path C:\$msiFileName
Start-Process msiexec.exe -ArgumentList "/i C:\$msiFileName /qn /norestart RUN_SERVICE_AS_LOCAL_SYSTEM=1" -Wait
$confFile = 'cloudbase-init.conf'
$confPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\"
$confContent = @"
[DEFAULT]
# Which devices to inspect for a possible configuration drive (metadata).
config_drive_raw_hhd=true
config_drive_cdrom=true
config_drive_vfat=true
bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\
verbose=true
debug=true
retry_count=5
logdir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
logfile=cloudbase-init.log
mtu_use_dhcp_config=false
ntp_use_dhcp_config=false
check_latest_version=false
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService, cloudbaseinit.metadata.services.base.EmptyMetadataService
plugins=cloudbaseinit.plugins.common.userdata.UserDataPlugin, cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin
allow_reboot=true
"@
New-Item -Path $confPath -Name $confFile -ItemType File -Force -Value $confContent | Out-Null
#Start-Process sc.exe -ArgumentList "config cloudbase-init start= delayed-auto" -wait | Out-Null
Remove-Item -Path ($confPath + "cloudbase-init-unattend.conf") -Confirm:$false 
Remove-Item -Path ($confPath + "Unattend.xml") -Confirm:$false 
$localScriptContent = @"
#for cloudbase-init to read our user-data we need the volume to be named "config-2". This script will seek and rename the volume
`$userDataFileName = "user-data"
`$drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3" | Select-Object -ExpandProperty DeviceID
foreach (`$drive in `$drives) {
    `$filePath = Join-Path -Path `$drive -ChildPath `$userDataFileName
    if (Test-Path `$filePath -PathType Leaf) {
        Set-Volume -Driveletter `$drive.Replace(":", "") -NewFileSystemLabel "config-2"
        shutdown -r -t 2
    } 
}
"@
New-Item -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts" -Name "RenameDrive.ps1" -ItemType File -Force -Value $localScriptContent | Out-Null
Unblock-File -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\RenameDrive.ps1"
Remove-Item C:\$msiFileName -Confirm:$false


#install xen tools from citrix
$toolsmsiLocation = 'https://downloads.xenserver.com/vm-tools-windows/9.3.3'
$toolsmsiFileName = 'managementagentx64.msi'
Invoke-WebRequest -Uri ($toolsmsiLocation + '/' + $toolsmsiFileName) -OutFile C:\$toolsmsiFileName
Start-Process msiexec.exe -ArgumentList "/i C:\$toolsmsiFileName /quiet /forcerestart" -Wait
Remove-Item C:\$toolsmsiFileName -Confirm:$false

# Reset auto logon count
# https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0

