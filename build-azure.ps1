#!/usr/local/bin/pwsh
param(
  [switch]$SkipPester,
  [switch]$ServerOnly,
  [switch]$TentacleOnly,
  [string]$OctopusVersion,
  [switch]$retainondestroy,
  [switch]$debug
)

. Tests/powershell-helpers.ps1

Start-Transcript .\vagrant-azure.log

Test-EnvVar AZURE_VM_PASSWORD
Test-EnvVar AZURE_SUBSCRIPTION_ID
Test-EnvVar AZURE_TENANT_ID
Test-EnvVar AZURE_CLIENT_ID
Test-EnvVar AZURE_CLIENT_SECRET

Set-OctopusDscEnvVars @PSBoundParameters

if (-not (Test-AppExists "vagrant")) {
  Write-Output "Please install vagrant from vagrantup.com."
  exit 1
}
Write-Output "Vagrant installed - good."

if (-not (Test-AppExists "azure")) {
  Write-Output "Azure CLI not found. Please install from https://docs.microsoft.com/en-us/azure/xplat-cli-install."
  exit 1
}
Write-Output "Azure CLI installed - good."

Test-CustomVersionOfVagrantDscPluginIsInstalled
Test-PluginInstalled "vagrant-azure" "2.0.0.pre7"
Test-PluginInstalled "vagrant-winrm-syncedfolders"
Test-PluginInstalled "vagrant-winrm-file-download"

Remove-OldLogsBeforeNewRun

if(-not $SkipPester) {
  Invoke-PesterTests
} else {
  Write-Output "-SkipPester was specified, skipping pester tests"
}

Write-Output "Running 'vagrant up --provider azure'"

Invoke-VagrantWithRetries -provider azure

Write-Output "'vagrant up' exited with exit code $LASTEXITCODE"

if ($LASTEXITCODE -ne 0) {
  Write-Output "Vagrant up failed with exit code $LASTEXITCODE"
  Write-Output "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $LASTEXITCODE
}

Write-Output "Don't forget to run 'cleanup-azure.ps1' when you have finished"
