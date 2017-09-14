#!/usr/local/bin/powershell

. Tests/powershell-helpers.ps1

Test-EnvVar AZURE_VM_PASSWORD
Test-EnvVar AZURE_SUBSCRIPTION_ID
Test-EnvVar AZURE_TENANT_ID
Test-EnvVar AZURE_CLIENT_ID
Test-EnvVar AZURE_CLIENT_SECRET

if (-not (Test-AppExists "vagrant")) {
  write-host "Please install vagrant from vagrantup.com."
  exit 1
}
write-host "Vagrant installed - good."

if (-not (Test-AppExists "azure")) {
  write-host "Azure CLI not found. Please install from https://docs.microsoft.com/en-us/azure/xplat-cli-install."
  exit 1
}
write-host "Azure CLI installed - good."

Test-PluginInstalled "vagrant-dsc"
Test-PluginInstalled "vagrant-azure" "2.0.0.pre7"
Test-PluginInstalled "vagrant-winrm"
Test-PluginInstalled "vagrant-winrm-syncedfolders"

Import-Module PSScriptAnalyzer
$excludedRules = @('PSUseShouldProcessForStateChangingFunctions', 
  'PSAvoidUsingUserNameAndPassWordParams', 
  'PSAvoidUsingConvertToSecureStringWithPlainText')
$results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude $excludedRules
write-output $results
write-output "PSScriptAnalyzer found $($results.length) issues"
if ($results.length -gt 0) {
  echo "Aborting as PSScriptAnalyzer found issues."
  exit $results.length
}

echo "Running Pester Tests"
Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -EnableExit

echo "Running 'vagrant up --provider azure'"
vagrant up --provider azure # --debug &> vagrant.log

echo "'vagrant up' exited with exit code $LASTEXITCODE"

if ($LASTEXITCODE -ne 0)
{
  echo "Vagrant up failed with exit code $LASTEXITCODE"
  echo "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $LASTEXITCODE
}

echo "Dont forget to run 'cleanup-azure.ps1' when you have finished"
