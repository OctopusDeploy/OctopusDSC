#credit: https://msdn.microsoft.com/en-us/powershell/dsc/troubleshooting#my-resources-wont-update-how-to-reset-the-cache

if (Test-Path 'C:\Windows\System32\WindowsPowerShell\v1.0\modules\OctopusDSC') {
  remove-item 'C:\Windows\System32\WindowsPowerShell\v1.0\modules\OctopusDSC' -force -recurse
}

### find the process that is hosting the DSC engine
$dscProcessID = Get-WmiObject msft_providers | Where-Object {$_.provider -like 'dsccore'} | Select-Object -ExpandProperty HostProcessIdentifier

if ($dscProcessID -ne $null) {
  ### Stop the process
  Get-Process -Id $dscProcessID | Stop-Process -force
}
