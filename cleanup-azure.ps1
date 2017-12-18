#!/usr/local/bin/pwsh

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

#todo: check vagrant status and exit cleanly if not running

write-host "Running 'vagrant destroy -f'"
& vagrant destroy -f
$VagrantDestroyExitCode=$LASTEXITCODE
write-host "'vagrant destroy' exited with exit code $VagrantDestroyExitCode"

if ($VagrantDestroyExitCode -ne 0) {
  write-host "Vagrant destroy failed with exit code $VagrantDestroyExitCode"
  write-host "##teamcity[buildStatus text='{build.status.text}. Vagrant cleanup failed. Action required.']"
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
