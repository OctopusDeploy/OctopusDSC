#!/usr/local/bin/pwsh
param(
  [switch]$offline,
  [switch]$SkipPester,
  [switch]$ServerOnly,
  [switch]$TentacleOnly,
  [string]$PreReleaseVersion
)

Start-Transcript .\vagrant-virtualbox.log

# Clear the OctopusDSCTestMode Env Var
if(Test-Path env:\OctopusDSCTestMode)
{
  get-item env:\OctopusDSCTestMode | Remove-Item
}
if($ServerOnly -and $TentacleOnly)
{
  throw "Cannot specify both 'ServerOnly' and 'TentacleOnly'"
}

if($ServerOnly)
{
  Write-Output "'ServerOnly' switch detected, running only server-related Integration tests"
  $env:OctopusDSCTestMode = 'ServerOnly'
}

if($TentacleOnly)
{
  Write-Output "'TentacleOnly' switch detected, running only tentacle-related Integration tests"
  $env:OctopusDSCTestMode = 'TentacleOnly'
}

# Allow testing pre-releases
if(Test-Path Env:\OctopusDSCPreReleaseVersion)
{
  get-item env:\OctopusDSCPreReleaseVersion| Remove-Item
}

if($null -ne $PreReleaseVersion)
{
  $env:OctopusDSCPreReleaseVersion = $PreReleaseVersion
}


if($offline)   # if you want to use offline, then you need a v3 and a v4 installer locally in the .\Tests folder (gitignored)
{
  Write-Warning "Offline run requested, writing an offline.config file"

  if(-not (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.4.*.msi"}))
  {
    Write-Warning "To run tests offline, you will need a v4 installer in the .\Tests folder"
    throw
  }

  if(-not (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.3.*.msi"}))
  {
    Write-Warning "To run tests offline, you will need a v3 installer in the .\Tests folder"
    throw
  }

  [pscustomobject]@{
      v4file = (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.3.*.msi"} | Select-Object -first 1 | Select-Object -expand Name);
      v3file = (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.4.*.msi"} | Select-Object -first 1 | Select-Object -expand Name);
  } | ConvertTo-Json | Out-File ".\Tests\offline.config"
}
else {
  # make sure the offline.config is not there
  Remove-item ".\tests\offline.config" -verbose -ErrorAction SilentlyContinue
}

. Tests/powershell-helpers.ps1

if (-not (Test-AppExists "vagrant")) {
  Write-Output "Please install vagrant from vagrantup.com."
  exit 1
}
Write-Output "Vagrant installed - good."

if (-not (Test-AppExists "VBoxManage")) {
  Write-Output "Please install VirtualBox from virtualbox.org and ensure the installation path is added to the system environment path."
  exit 1
}
Write-Output "VirtualBox installed - good."

Test-CustomVersionOfVagrantDscPluginIsInstalled
Test-PluginInstalled "vagrant-winrm-syncedfolders"

Write-Output "Importing Pester module"
Test-PowershellModuleInstalled "Pester"
Test-PowershellModuleInstalled "PSScriptAnalyzer"
Import-Module Pester -verbose -force

if(-not $SkipPester)
{
  Write-Output "Running Pester Tests"
  $result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
  if ($result.FailedCount -gt 0) {
    exit 1
  }
}
else
{
  Write-Output "-SkipPester was specified, skipping pester tests"
}

Write-Output "Running 'vagrant up --provider virtualbox'"
vagrant up --provider virtualbox | Tee-Object -FilePath vagrant.log  #  --no-destroy-on-error --debug

Write-Output "Dont forget to run 'vagrant destroy -f' when you have finished"

stop-transcript
