# Runs inside Windows 11 ARM guest as SYSTEM. Idempotent. Log: C:\Windows\Temp\tune.log
$ErrorActionPreference = 'Continue'
Start-Transcript C:\Windows\Temp\tune.log -Force | Out-Null
function Reg($p,$n,$v,$t='DWord'){ if(!(Test-Path $p)){New-Item $p -Force|Out-Null}; New-ItemProperty $p -Name $n -Value $v -PropertyType $t -Force|Out-Null }
function Svc($names){ foreach($s in $names){ if(Get-Service $s -EA 0){ Stop-Service $s -Force -EA 0; Set-Service $s -StartupType Disabled -EA 0; "svc off: $s" } } }

# --- Telemetry / tracking ---
$dc='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
Reg $dc AllowTelemetry 0; Reg $dc DoNotShowFeedbackNotifications 1; Reg $dc AllowCommercialDataPipeline 0
Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' AllowTelemetry 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' DisabledByGroupPolicy 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' DisableWindowsConsumerFeatures 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' DisableSoftLanding 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' PublishUserActivities 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' EnableActivityFeed 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting' Disabled 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' DisableInventory 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' AITEnable 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows' CEIPEnable 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' AllowCortana 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' DisableWebSearch 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' ConnectedSearchUseWeb 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' TurnOffWindowsCopilot 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' DisableAIDataAnalysis 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' AllowNewsAndInterests 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' DODownloadMode 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' AllowGameDVR 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' DisableFileSyncNGSC 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' StartupBoostEnabled 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' BackgroundModeEnabled 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' MetricsReportingEnabled 0
# Not touched: WSearch/SysMain/Xbox/Gaming Services/Store services stay as they are (game needs them).
Svc 'DiagTrack','dmwappushservice','WerSvc','diagnosticshub.standardcollector.service','RetailDemo','MapsBroker','Fax','lfsvc'
$taskPaths='\Microsoft\Windows\Application Experience\','\Microsoft\Windows\Customer Experience Improvement Program\','\Microsoft\Windows\DiskDiagnostic\','\Microsoft\Windows\Feedback\Siuf\','\Microsoft\Windows\Windows Error Reporting\','\Microsoft\Windows\Flighting\','\Microsoft\Windows\Device Information\','\Microsoft\Windows\NetTrace\'
foreach($t in $taskPaths){ Get-ScheduledTask -TaskPath $t -EA 0 | Disable-ScheduledTask -EA 0 | Out-Null }

# --- Defender (Tamper Protection must be OFF in Windows Security UI, else values are reverted) ---
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' DisableAntiSpyware 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' DisableRealtimeMonitoring 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' DisableBehaviorMonitoring 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' DisableOnAccessProtection 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' SpynetReporting 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' SubmitSamplesConsent 2
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan' DisableScheduledScan 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' EnableSmartScreen 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\MRT' DontOfferThroughWUAU 1
try{ Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisableScriptScanning $true -MAPSReporting 0 -SubmitSamplesConsent 2 -PUAProtection Disabled -EA Stop; Add-MpPreference -ExclusionPath 'C:\' -EA Stop }catch{ "Set-MpPreference failed: $_" }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender\' -EA 0 | Disable-ScheduledTask -EA 0 | Out-Null

# --- Performance ---
powercfg /h off | Out-Null
Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' EnableVirtualizationBasedSecurity 0
Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' Enabled 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' NoAutoRebootWithLoggedOnUsers 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' AUOptions 2
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' ExcludeWUDriversInQualityUpdate 1
Get-ScheduledTask -EA 0 | ?{ $_.TaskName -match 'OneDrive|MicrosoftEdgeUpdate' } | Disable-ScheduledTask -EA 0 | Out-Null
$ex='Registry::HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion'
Reg "$ex\Explorer\Advanced" TaskbarAnimations 0
Reg "$ex\Explorer\Advanced" TaskbarDa 0
Reg "$ex\Explorer\Advanced" ShowTaskViewButton 0
Reg "$ex\Search" BingSearchEnabled 0
Reg "$ex\ContentDeliveryManager" SilentInstalledAppsEnabled 0
Reg "$ex\AdvertisingInfo" Enabled 0

# --- Remove bloat apps (Xbox, Store, Gaming Services, runtimes are NOT in this list) ---
$bloat='Clipchamp','BingNews','BingWeather','BingSearch','GetHelp','Getstarted','MicrosoftSolitaireCollection','MicrosoftOfficeHub','MicrosoftStickyNotes','Todos','WindowsFeedbackHub','WindowsMaps','PowerAutomateDesktop','YourPhone','ZuneMusic','ZuneVideo','People','MSTeams','OutlookForWindows','Copilot','QuickAssist','DevHome','WindowsAlarms','WindowsSoundRecorder'
foreach($b in $bloat){
  Get-AppxPackage -AllUsers "*$b*" -EA 0 | Remove-AppxPackage -AllUsers -EA 0
  Get-AppxProvisionedPackage -Online -EA 0 | ?{ $_.DisplayName -like "*$b*" } | Remove-AppxProvisionedPackage -Online -EA 0 | Out-Null
}
Stop-Transcript | Out-Null
"DONE"
