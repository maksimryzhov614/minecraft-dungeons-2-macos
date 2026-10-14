# Phase 2: runs inside Windows 11 ARM guest as SYSTEM. Idempotent. Log: C:\Windows\Temp\tune2.log
$ErrorActionPreference = 'Continue'
Start-Transcript C:\Windows\Temp\tune2.log -Force | Out-Null
function Reg($p,$n,$v,$t='DWord'){ if(!(Test-Path $p)){New-Item $p -Force|Out-Null}; New-ItemProperty $p -Name $n -Value $v -PropertyType $t -Force|Out-Null }
function Svc($names){ foreach($s in $names){ if(Get-Service $s -EA 0){ Stop-Service $s -Force -EA 0; Set-Service $s -StartupType Disabled -EA 0; "svc off: $s" } } }

# --- More background services (gaming VM, no shared features needed) ---
Svc 'PcaSvc','Dusmvc','RemoteRegistry','SmsRouter','WpcDesktopSvc','TabletInputService','SessionEnv','TermService'

# --- Leftover telemetry scheduled tasks by name anywhere in the tree ---
Get-ScheduledTask -EA 0 | ?{ $_.TaskName -match 'Ceip|Telemetry|MSPerfTrace|UsbCeip|KernelCeip' } | Disable-ScheduledTask -EA 0 | Out-Null

# --- Interactive user hive settings ---
$sid=(Get-Item 'Registry::HKEY_USERS').GetSubKeyNames() | ?{ $_ -match '^S-1-5-21-' -and $_ -notmatch '_Classes$' } | Select-Object -First 1
if($sid){
  $u="Registry::HKEY_USERS\$sid"
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarDa 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarAnimations 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ShowTaskViewButton 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarAnimationsFast 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SilentInstalledAppsEnabled 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SystemPaneSuggestionsEnabled 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled 0
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 0
  Reg "$u\Control Panel\Desktop" MenuShowDelay '20' 'String'
  Reg "$u\Control Panel\Mouse" MouseSpeed 0
  Reg "$u\Control Panel\Mouse" MouseSensitivity '10' 'String'
  Reg "$u\Software\Microsoft\GameBar" AutoGameModeEnabled 1
  Reg "$u\Software\Microsoft\Windows\CurrentVersion\GameDVR" GameDVR_Enabled 0
  "user hive: $sid"
} else { "user hive: NOT FOUND" }

# --- Remove remaining AI/Copilot-ish packages and OneDrive leftovers ---
foreach($b in 'MicrosoftWindows.Client.CoreAI','Copilot'){
  Get-AppxPackage -AllUsers "*$b*" -EA 0 | Remove-AppxPackage -AllUsers -EA 0
  Get-AppxProvisionedPackage -Online -EA 0 | ?{ $_.DisplayName -like "*$b*" } | Remove-AppxProvisionedPackage -Online -EA 0 | Out-Null
}
if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe'){
  Stop-Process OneDrive -Force -EA 0
  & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall 2>&1 | Out-Null
  & "$env:SystemRoot\System32\OneDriveSetup.exe" /uninstall 2>&1 | Out-Null
  "onedrive uninstalled if present"
}

Stop-Transcript | Out-Null
"DONE"
