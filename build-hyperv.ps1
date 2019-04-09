#!/usr/local/bin/pwsh
param(
  [switch]$offline,
  [switch]$SkipPester,
  [switch]$ServerOnly,
  [switch]$TentacleOnly,
  [string]$OctopusVersion,
  [switch]$retainondestroy,
  [switch]$debug
)

. Tests/powershell-helpers.ps1

Start-Transcript .\vagrant-hyperv.log -Append

Set-OctopusDscEnvVars @PSBoundParameters

# remove psreadline as it interferes with the SMB password prompt
if(Get-Module PSReadLine)
{
  Remove-Module PSReadLine
}

if (-not (Test-AppExists "vagrant")) {
  Write-Output "Please install vagrant from vagrantup.com."
  exit 1
}
Write-Output "Vagrant installed - good."

if ((Get-CimInstance Win32_OperatingSystem).PRODUCTTYPE -eq 1) {
    # client OS detected
    if ((Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V').State -eq 'Disabled') {
        Write-Output 'Please install Hyper-V.'
        exit 1
    }
}
else {
    # server OS detected
    if ((Get-WindowsFeature 'Hyper-V').State -eq 'Disabled') {
        Write-Output 'Please install Hyper-V.'
        exit 1
    }
}
Write-Output "Hyper-V installed - good."

if (-not (Get-VMSwitch -SwitchType External -Name 'External Connection' -ErrorAction SilentlyContinue)) {
    Write-Output "Please create an external virtual switch named 'External Connection'."
    exit 1
}
Write-Output "External virtual switch detected - good."

Test-CustomVersionOfVagrantDscPluginIsInstalled
Test-PluginInstalled "vagrant-winrm-syncedfolders"

if(-not $SkipPester)
{
  Write-Output "Running Pester Tests"
  $result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
  if ($result.FailedCount -gt 0) {
    exit 1
  }
}
else
{
  Write-Output "-SkipPester was specified, skipping pester tests"
}

$splat = @{
  provider="hyperv";
  retainondestroy = $retainondestroy.IsPresent; # set to $true to override in this script
  debug = $debug.IsPresent; # set to $true to override in this script
}

Invoke-VagrantWithRetries @splat

Write-Output "Don't forget to run 'vagrant destroy -f' when you have finished"

stop-transcript
