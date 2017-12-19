#!/usr/local/bin/pwsh

. Tests/powershell-helpers.ps1

Test-EnvVar AZURE_VM_PASSWORD
Test-EnvVar AZURE_SUBSCRIPTION_ID
Test-EnvVar AZURE_TENANT_ID
Test-EnvVar AZURE_CLIENT_ID
Test-EnvVar AZURE_CLIENT_SECRET

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

Test-PluginInstalled "vagrant-dsc"
Test-PluginInstalled "vagrant-azure" "2.0.0.pre7"
Test-PluginInstalled "vagrant-winrm"
Test-PluginInstalled "vagrant-winrm-syncedfolders"

Write-Output "Running Pester Tests"
$result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
if ($result.FailedCount -gt 0) {
  exit 1
}

Write-Output "Running 'vagrant up --provider azure'"
vagrant up --provider azure # --debug &> vagrant.log

Write-Output "'vagrant up' exited with exit code $LASTEXITCODE"

if ($LASTEXITCODE -ne 0)
{
  Write-Output "Vagrant up failed with exit code $LASTEXITCODE"
  Write-Output "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $LASTEXITCODE
}

Write-Output "Dont forget to run 'cleanup-azure.ps1' when you have finished"
