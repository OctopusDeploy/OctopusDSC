#!/usr/local/bin/pwsh

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
write-host "AWS CLI installed - good."

Test-PluginInstalled "vagrant-aws"
Test-PluginInstalled "vagrant-aws-winrm"
Test-PluginInstalled "vagrant-dsc"
Test-PluginInstalled "vagrant-winrm"
Test-PluginInstalled "vagrant-winrm-syncedfolders"

echo "Running Pester Tests"
$result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
if ($result.FailedCount -gt 0) {
  exit 1
}

$randomGuid=[guid]::NewGuid()
$keyName = "vagrant_$randomGuid"

[Environment]::SetEnvironmentVariable("KEY_NAME", $keyName)

write-host "Creating new key-pair $keyName"
$key = (& aws ec2 create-key-pair --key-name $keyName --query 'KeyMaterial' --output text --region ap-southeast-2)
if ($LASTEXITCODE -ne 0) {
  write-host "Failed to create aws key-pair."
  write-host "##teamcity[buildStatus text='{build.status.text}. AWS setup failed.']"
  exit 1
}
Set-Content -Path "$keyName.pem" -Value $key

if (Test-AppExists "chmod") {
  write-host "Setting permissions on pem file '$keyName.pem'"
  & chmod 400 "./$keyName.pem"
}
else {
  write-host "chmod not found, skipping setting permissions on pem file"
}

write-host "Adding vagrant box"
vagrant box add OctopusDeploy/dsc-test-server-windows-2012-r2 https://s3-ap-southeast-2.amazonaws.com/octopus-vagrant-boxes/vagrant/json/OctopusDeploy/amazon-ebs/dsc-test-server-windows-2012-r2.json --force

write-host "Ensuring vagrant box is latest"
vagrant box update --box OctopusDeploy/dsc-test-server-windows-2012-r2 --provider aws

write-host "Running 'vagrant up --provider aws'"
vagrant up --provider aws  | Tee-Object -FilePath vagrant.log
echo "'vagrant up' exited with exit code $LASTEXITCODE"

if ($LASTEXITCODE -ne 0)
{
  echo "Vagrant up failed with exit code $LASTEXITCODE"
  echo "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $LASTEXITCODE
}

echo "Dont forget to run 'cleanup-aws.ps1' when you have finished"
