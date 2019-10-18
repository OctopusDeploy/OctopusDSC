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

Start-Transcript .\vagrant-aws.log

Test-EnvVar AWS_ACCESS_KEY_ID
Test-EnvVar AWS_SECRET_ACCESS_KEY
Test-EnvVar AWS_SUBNET_ID
Test-EnvVar AWS_SECURITY_GROUP_ID

Set-OctopusDscEnvVars @PSBoundParameters

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
Test-CustomVersionOfVagrantDscPluginIsInstalled
Test-PluginInstalled "vagrant-winrm-syncedfolders"

if(-not $SkipPester) {
  Write-Output "##teamcity[blockOpened name='Pester tests']"
  Write-Output "Importing Pester module"
  Test-PowershellModuleInstalled "Pester" "4.9.0"
  Test-PowershellModuleInstalled "PSScriptAnalyzer" "1.18.3"
  Import-Module Pester -force
  Write-Output "Running Pester Tests"
  $result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
  if ($result.FailedCount -gt 0) {
    exit 1
  }
  Write-Output "##teamcity[blockClosed name='Pester tests']"
} else {
  Write-Output "-SkipPester was specified, skipping pester tests"
}

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
} else {
  Write-Output "chmod not found, skipping setting permissions on pem file"
}

Write-Output "Adding vagrant box"
vagrant box add OctopusDeploy/dsc-test-server-windows-server-1803 https://s3-ap-southeast-2.amazonaws.com/octopus-vagrant-boxes/vagrant/json/OctopusDeploy/amazon-ebs/dsc-test-server-windows-server-1803.json --force

Write-Output "Ensuring vagrant box is latest"
vagrant box update --box OctopusDeploy/dsc-test-server-windows-server-1803 --provider aws

$splat = @{
  provider="aws";
  retainondestroy = $retainondestroy.IsPresent;
  debug = $debug.IsPresent;
}

Invoke-VagrantWithRetries @splat

if ($LASTEXITCODE -ne 0) {
  Write-Output "Vagrant up failed with exit code $LASTEXITCODE"
  Write-Output "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $LASTEXITCODE
}

Write-Output "Don't forget to run 'cleanup-aws.ps1' when you have finished"
