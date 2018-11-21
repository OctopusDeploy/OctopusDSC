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
  Write-Output "Please install aws-cli. See https://docs.aws.amazon.com/cli/latest/userguide/installing.html."
  exit 1
}
Write-Output "AWS CLI installed - good."

Test-PluginInstalled "vagrant-aws"
Test-PluginInstalled "vagrant-aws-winrm"
Test-PluginInstalled "vagrant-dsc"
Test-PluginInstalled "vagrant-winrm-syncedfolders"

Write-Output "##teamcity[blockOpened name='Pester tests']"
Write-Output "Importing Pester module"
Test-PowershellModuleInstalled "Pester"
Test-PowershellModuleInstalled "PSScriptAnalyzer"
Import-Module Pester -verbose -force

Write-Output "Running Pester Tests"
$result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
if ($result.FailedCount -gt 0) {
  exit 1
}
Write-Output "##teamcity[blockClosed name='Pester tests']"

$randomGuid=[guid]::NewGuid()
$keyName = "vagrant_$randomGuid"

[Environment]::SetEnvironmentVariable("KEY_NAME", $keyName)

Write-Output "Creating new key-pair $keyName"
$key = (& aws ec2 create-key-pair --key-name $keyName --query 'KeyMaterial' --output text --region ap-southeast-2)
if ($LASTEXITCODE -ne 0) {
  Write-Output "Failed to create aws key-pair."
  Write-Output "##teamcity[buildStatus text='{build.status.text}. AWS setup failed.']"
  exit 1
}
Set-Content -Path "$keyName.pem" -Value $key

if (Test-AppExists "chmod") {
  Write-Output "Setting permissions on pem file '$keyName.pem'"
  & chmod 400 "./$keyName.pem"
}
else {
  Write-Output "chmod not found, skipping setting permissions on pem file"
}

Write-Output "Adding vagrant box"
vagrant box add OctopusDeploy/dsc-test-server-windows-server-1803 https://s3-ap-southeast-2.amazonaws.com/octopus-vagrant-boxes/vagrant/json/OctopusDeploy/amazon-ebs/dsc-test-server-windows-server-1803.json --force

Write-Output "Ensuring vagrant box is latest"
vagrant box update --box OctopusDeploy/dsc-test-server-windows-server-1803 --provider aws

Write-Output "Running 'vagrant up --provider aws'"
vagrant up --provider aws  | Tee-Object -FilePath vagrant.log
Write-Output "'vagrant up' exited with exit code $LASTEXITCODE"


if ($LASTEXITCODE -ne 0)
{
  Write-Output "Vagrant up failed with exit code $LASTEXITCODE"
  Write-Output "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $LASTEXITCODE
}


Write-Output "Dont forget to run 'cleanup-aws.ps1' when you have finished"
