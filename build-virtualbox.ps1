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
Start-Transcript .\vagrant-virtualbox.log

Set-OctopusDscEnvVars @PSBoundParameters

if (-not (Test-AppExists "vagrant")) {
  Write-Output "Please install vagrant from vagrantup.com."
  exit 1
}
Write-Output "Vagrant installed - good."

if (-not (Test-AppExists "VBoxManage")) {
  Write-Output "Please install VirtualBox from virtualbox.org and ensure the installation path is added to the system environment path."
  exit 1
}
Write-Output "VirtualBox installed - good."

Test-CustomVersionOfVagrantDscPluginIsInstalled
Test-PluginInstalled "vagrant-winrm-syncedfolders"
Test-PluginInstalled "vagrant-winrm-file-download"

Remove-OldLogsBeforeNewRun

if(-not $SkipPester) {
  Invoke-PesterTests
} else {
  Write-Output "-SkipPester was specified, skipping pester tests"
}

$splat = @{
  provider = 'virtualbox';
  retainondestroy = $retainondestroy.IsPresent;
  debug = $debug.IsPresent;
}

Invoke-VagrantWithRetries @splat

Write-Output "Don't forget to run 'vagrant destroy -f' when you have finished"

stop-transcript
