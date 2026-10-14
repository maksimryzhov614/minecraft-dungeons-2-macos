$ErrorActionPreference='Continue'
$out="cpu10M_ms: " + (Measure-Command { for($i=0;$i -lt 10000000;$i++){} }).TotalMilliseconds
$os=Get-CimInstance Win32_OperatingSystem
$out += "freeGB: $([math]::Round($os.FreePhysicalMemory/1MB,1)) totalGB: $([math]::Round($os.TotalVisibleMemorySize/1MB,1))"
$pf=Get-CimInstance Win32_PageFileUsage -EA 0
if($pf){ $out += "pagefile: $($pf.AllocatedBaseSize)MB used $($pf.CurrentUsage)MB" } else { $out += "pagefile: none" }
$out | Out-File C:\Windows\Temp\bench.txt
$out | Out-String | Write-Output
