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

#todo: check vagrant status and exit cleanly if not running

Write-Output "Running 'vagrant destroy -f'"
& vagrant destroy -f
$VagrantDestroyExitCode=$LASTEXITCODE
Write-Output "'vagrant destroy' exited with exit code $VagrantDestroyExitCode"

if ($VagrantDestroyExitCode -ne 0) {
  Write-Output "Vagrant destroy failed with exit code $VagrantDestroyExitCode"
  Write-Output "##teamcity[buildStatus text='{build.status.text}. Vagrant cleanup failed. Action required.']"
  exit $VagrantDestroyExitCode
}

# in some circumstances, vagrant doesn't think the vm exists, but the resource group does exist
# this will mean that new runs will use the existing resource group, which is rarely what we want
$json = & azure group list --json
$groups = ("{`"items`": $json }" | ConvertFrom-Json)
$group = $groups.items | where-object { $_.name -eq "OctopusDSCTesting" }
if ($group) {
  & azure group delete --quiet OctopusDSCTesting
}
