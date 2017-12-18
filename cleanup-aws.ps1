#!/usr/local/bin/pwsh

. Tests/powershell-helpers.ps1

Test-EnvVar AWS_ACCESS_KEY_ID
Test-EnvVar AWS_SECRET_ACCESS_KEY
Test-EnvVar AWS_SUBNET_ID
Test-EnvVar AWS_SECURITY_GROUP_ID

if (-not (Test-AppExists "vagrant")) {
  Write-Output "Please install vagrant from vagrantup.com."
  exit 1
}
Write-Output "Vagrant installed - good."

if (-not (Test-AppExists "aws")) {
  Write-Output "Please install aws-cli. See http://docs.aws.amazon.com/cli/latest/userguide/installing.html."
  exit 1
}

Test-PluginInstalled "vagrant-aws"
Test-PluginInstalled "vagrant-aws-winrm"
Test-PluginInstalled "vagrant-dsc"
Test-PluginInstalled "vagrant-winrm"
Test-PluginInstalled "vagrant-winrm-syncedfolders"

#get key name from file
$files = @(Get-ChildItem -filter "vagrant_*.pem")

if ($files.length -eq 0) {
  Write-Output "No key pair (vagrant_GUID.pem) found - unable to cleanup."
  exit 1
}

$keyName = $files[0].BaseName
$env:KEY_NAME = $keyName
Write-Output "Using key pair $keyName.pem"

#todo: check vagrant status and exit cleanly if not running

Write-Output "Running 'vagrant destroy -f'"
& vagrant destroy -f
$VagrantDestroyExitCode=$LASTEXITCODE
Write-Output "'vagrant destroy' exited with exit code $VagrantDestroyExitCode"

Write-Output "Removing local key-pair"
remove-item $files[0].Name -force

Write-Output "Deleting aws key-pair"
& aws ec2 delete-key-pair --key-name $keyName --region ap-southeast-2

if ($VagrantDestroyExitCode -ne 0) {
  Write-Output "Vagrant destroy failed with exit code $VagrantDestroyExitCode"
  Write-Output "##teamcity[buildStatus text='{build.status.text}. Vagrant cleanup failed. Action required.']"

  exit $VagrantDestroyExitCode
}