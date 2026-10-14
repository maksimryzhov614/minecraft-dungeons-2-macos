$ErrorActionPreference='Continue'
$lc = Get-ChildItem 'C:\Program Files (x86)\Steam\userdata' -Recurse -Filter localconfig.vdf | Select-Object -First 1
if(!$lc){ 'localconfig NOT FOUND'; exit }
Copy-Item $lc.FullName "$($lc.FullName).bak-3p" -Force
$lines = Get-Content $lc.FullName
for($i=0;$i -lt $lines.Count;$i++){
  if($lines[$i] -match 'LaunchOptions'){ $lines[$i] = "\t\t`"LaunchOptions`"\t\t`"-force -d3d11 -nosplash`""; "patched line $i" }
}
Set-Content -Path $lc.FullName -Value $lines
'launch options now:'
Get-ChildItem 'C:\Program Files (x86)\Steam\userdata' -Recurse -Filter localconfig.vdf | Get-Content | Select-String -Pattern 'LaunchOptions'
