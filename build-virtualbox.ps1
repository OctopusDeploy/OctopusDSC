#!/usr/local/bin/powershell
param(
  $version = 'latest',
  [switch]$offline
)

if($version -ne 'latest')
{
# https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.4.0.0-v4-14812.msi

# go get the 4.0 installer.

}

. Tests/powershell-helpers.ps1

if (-not (Test-AppExists "vagrant")) {
  write-host "Please install vagrant from vagrantup.com."
  exit 1
}
write-host "Vagrant installed - good."

if (-not (Test-AppExists "VBoxManage")) {
  write-host "Please install VirtualBox from virtualbox.org."
  exit 1
}
write-host "VirtualBox installed - good."

Test-PluginInstalled "vagrant-dsc"
Test-PluginInstalled "vagrant-winrm"
Test-PluginInstalled "vagrant-winrm-syncedfolders"

Import-Module PSScriptAnalyzer
$excludedRules = @(
    'PSUseShouldProcessForStateChangingFunctions', 
    'PSUseSingularNouns' # , 
    # 'PSAvoidUsingConvertToSecureStringWithPlainText'
    )
$results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude $excludedRules
write-output $results
write-output "PSScriptAnalyzer found $($results.length) issues"
if ($results.length -gt 0) {
  echo "Aborting as PSScriptAnalyzer found issues."
  exit $results.length
}

echo "Running Pester Tests"
Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -EnableExit

echo "Running 'vagrant up --provider virtualbox'"
vagrant up --provider virtualbox --no-destroy-on-error --debug | Tee-Object -FilePath vagrant.log  

echo "Dont forget to run 'vagrant destroy -f' when you have finished"