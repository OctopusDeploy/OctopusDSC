#!/usr/local/bin/powershell

. Tests/powershell-helpers.ps1

Test-EnvVar AWS_ACCESS_KEY_ID
Test-EnvVar AWS_SECRET_ACCESS_KEY
Test-EnvVar AWS_SUBNET_ID
Test-EnvVar AWS_SECURITY_GROUP_ID

if (-not (Test-AppExists "vagrant")) {
  write-host "Please install vagrant from vagrantup.com."
  exit 1
}
write-host "Vagrant installed - good."

if (-not (Test-AppExists "aws")) {
  write-host "Please install aws-cli. See http://docs.aws.amazon.com/cli/latest/userguide/installing.html."
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
  write-host "No key pair (vagrant_GUID.pem) found - unable to cleanup."
  exit 1
}

$keyName = $files[0].BaseName
$env:KEY_NAME = $keyName
write-host "Using key pair $keyName.pem"

#todo: check vagrant status and exit cleanly if not running

echo "Running 'vagrant destroy -f'"
& vagrant destroy -f
$VagrantDestroyExitCode=$LASTEXITCODE
write-host "'vagrant destroy' exited with exit code $VagrantDestroyExitCode"

write-host "Removing local key-pair"
remove-item $files[0].Name -force

write-host "Deleting aws key-pair"
& aws ec2 delete-key-pair --key-name $keyName --region ap-southeast-2

if ($VagrantDestroyExitCode -ne 0) {
  write-host "Vagrant destroy failed with exit code $VagrantDestroyExitCode"
  write-host "##teamcity[buildStatus text='{build.status.text}. Vagrant cleanup failed. Action required.']"

  exit $VagrantDestroyExitCode
}
