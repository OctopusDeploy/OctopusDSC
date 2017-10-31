#!/usr/local/bin/powershell
param(
  [switch]$offline
)

Start-Transcript .\vagrant-hyperv.log

if($offline)   # if you want to use offline, then you need a v3 and a v4 installer locally in the .\Tests folder (gitignored)
{
  Write-Warning "Offline run requested, writing an offline.config file"

  if(-not (gci .\Tests | ? {$_.Name -like "Octopus.4.*.msi"}))
  {
    Write-Warning "To run tests offline, you will need a v4 installer in the .\Tests folder"
    throw
  }

  if(-not (gci .\Tests | ? {$_.Name -like "Octopus.3.*.msi"}))
  {
    Write-Warning "To run tests offline, you will need a v3 installer in the .\Tests folder"
    throw 
  }

  [pscustomobject]@{
      v4file = (gci .\Tests | ? {$_.Name -like "Octopus.3.*.msi"} | select -first 1 | select -expand Name);
      v3file = (gci .\Tests | ? {$_.Name -like "Octopus.4.*.msi"} | select -first 1 | select -expand Name);
  } | ConvertTo-Json | Out-File ".\Tests\offline.config"
}
else {
  # make sure the offline.config is not there
  Remove-item ".\tests\offline.config" -verbose -ErrorAction SilentlyContinue
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


echo "Running Pester Tests"
Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -EnableExit

echo "Running 'vagrant up --provider hyperv'"
vagrant up --provider hyperv | Tee-Object -FilePath vagrant.log  #  --no-destroy-on-error --debug

echo "Dont forget to run 'vagrant destroy -f' when you have finished"

stop-transcript 