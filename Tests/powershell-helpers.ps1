function Test-PluginInstalled($pluginName, $pluginVersion) {

  $result = (& vagrant plugin list)
  if ($null -eq $pluginVersion) {
    if ($result -like "*$pluginName *") {
      write-host "Vagrant plugin $pluginName exists - good."
    }
    else {
      write-host "Vagrant plugin $pluginName not installed."
      & vagrant plugin install $pluginName
      if ($LASTEXITCODE -ne 0) {
        write-host "Failed to automatically install vagrant plugin $($pluginName)" -foregroundcolor red
        exit 1
      }
    }
  }
  else {
    if ($result -like "*$pluginName ($pluginVersion)*") {
      write-host "Vagrant plugin $pluginName v$pluginVersion exists - good."
    }
    else {
      write-host "Vagrant plugin $pluginName v$pluginVersion not installed."
      & vagrant plugin install $pluginName --plugin-version "$pluginVersion"
    }
  }
}

function Test-EnvVar($variableName) {
  if (-not (Test-Path env:$variableName)) {
    write-host "Please set the $variableName environment variable" -foregroundcolor red
    exit 1
  }
}

function Test-AppExists($appName) {
  $command = Get-Command $appName -ErrorAction SilentlyContinue
  return $null -ne $command
}

function Import-PowerShellModule ($Name, $MinimumVersion) {
  Write-Output "Checking version for $moduleName..."
  $command = Get-Module $Name -listavailable
  if ($null -eq $command) {
    write-host "Please install $($Name): Install-Module -Name $Name -Force" -foregroundcolor red
    exit 1
  }

  if ($command.Count -gt 1)
  {
    $command = $command | Sort-Object -Property Version -Descending | Select-Object -First 1
  }


  if ($null -ne $MinimumVersion) {
    if ($command.Version -lt [System.Version]::Parse($MinimumVersion)) {
      write-host "Please install $($Name) $MinimumVersion or higher (you have version $($command.Version)): Update-Module -Name $Name -Force" -foregroundcolor red
      exit 1
    }
  }

  Write-Output "Importing module $Name with version $($command.Version)..."
  Import-Module -Name $Name -Version $command.Version
}

function Test-CustomVersionOfVagrantDscPluginIsInstalled() {  # does not deal well with machines that have two versioned folders under /gems/
  $path = Resolve-Path ~/.vagrant.d/gems/*/gems/vagrant-dsc-*/lib/vagrant-dsc/provisioner.rb |
            Sort-Object -descending |
            Select-Object -first 1 # sort and select to cope with multiple gem folders (upgraded vagrant)

  if (($null -ne $path) -and (Test-Path $path -ErrorAction SilentlyContinue)) {
    $content = Get-Content $path -raw
    if ($content.IndexOf("return version.stdout") -gt -1) {
      return;
    }
  }

  write-host "It doesn't appear that you've got the custom Octopus version of the vagrant-dsc plugin installed" -foregroundcolor red
  write-host "Please download it from github:" -foregroundcolor red
  write-host "  irm https://github.com/OctopusDeploy/vagrant-dsc/releases/download/v2.0.2/vagrant-dsc-2.0.2.gem -outfile vagrant-dsc-2.0.2.gem" -foregroundcolor red
  write-host "  vagrant plugin install vagrant-dsc-2.0.2.gem" -foregroundcolor red
  exit 1
}

function Test-LogContainsRetriableFailure($log) {
  if ($log.Contains("[WinRM::FS::Core::FileTransporter] Upload failed (exitcode: 0), but stderr present (WinRM::FS::Core::FileTransporterFailed)")) {
      return $true
  }

  Write-Warning "Attempted retry, but no retriable failures found"
  return $false
}

function Invoke-VagrantWithRetries {
  param(
    [ValidateSet("aws", "azure", "hyperv", "virtualbox")]
    $provider,
    $retries = 3,
    [switch]$retainondestroy,
    [switch]$debug
  )

  $attempts = 0
  $args = @(
    'up',
    '--provider',
    $provider
  )

  if($retainondestroy) {
    $args += '--no-destroy-on-error'
  }

  if($debug) {
    $args += '--debug'
  }

  do {
    Write-Output (@("Running Vagrant with arguments '", ($args -join " "), "'") -join "")
    Invoke-Expression "vagrant $args" -ErrorVariable stdErr 2>&1 | Tee-Object -FilePath vagrant.log
    Write-Output "'vagrant up' exited with exit code $LASTEXITCODE"
    $attempts = $attempts + 1
    $retryAgain = ($attempts -lt $retries) -and (Test-LogContainsRetriableFailure $stdErr) -and ($LASTEXITCODE -ne 0)
    if ($retryAgain) {
      Write-Output "Running 'vagrant destroy -f' to cleanup, so we can try again."
      vagrant destroy -f
    }
  } while ($retryAgain)
}

function Set-OctopusDSCEnvVars {
  param(
    [switch]$offline,
    [switch]$SkipPester,
    [switch]$ServerOnly,
    [switch]$TentacleOnly,
    [string]$OctopusVersion
  )

  if(-not $env:OctopusDSCVMSwitch)
  {
    $env:OctopusDSCVMSwitch = 'Default Switch' # Override this variable to use a different switch in hyper-v
  }

  # Clear the OctopusDSCTestMode Env Var
  if(Test-Path env:\OctopusDSCTestMode)  {
    get-item env:\OctopusDSCTestMode | Remove-Item
  }
  if($ServerOnly.IsPresent -and $TentacleOnly.IsPresent)  {
    throw "Cannot specify both 'ServerOnly' and 'TentacleOnly'"
  }

  if($ServerOnly.IsPresent)  {
    Write-Output "'ServerOnly' switch detected, running only server-related Integration tests"
    $env:OctopusDSCTestMode = 'ServerOnly'
  }

  if($TentacleOnly.IsPresent)  {
    Write-Output "'TentacleOnly' switch detected, running only tentacle-related Integration tests"
    $env:OctopusDSCTestMode = 'TentacleOnly'
  }

  # Allow testing pre-releases
  if(Test-Path Env:\OctopusDSCPreReleaseVersion)  {
    get-item env:\OctopusDSCPreReleaseVersion| Remove-Item
  }

  if($OctopusVersion -ne "")  {
    Write-Output "Setting pre-release version to $OctopusVersion"
    $env:OctopusDSCPreReleaseVersion = $OctopusVersion
  }

  # offline installers - saves downloading a ton of installer data, can speed things up on slow connections
  # only really useful for hyper-v and virtualbox. currently broken
  if($offline.IsPresent) {
    Set-OfflineConfig
  } else {
    # make sure the offline.config is not there
    Remove-item ".\tests\offline.config" -verbose -ErrorAction SilentlyContinue
  }
}

function Set-OfflineConfig {
  # if you want to use offline, then you need a v3 and a v4 MSI installer locally in the .\Tests folder (gitignored)

  Write-Warning "Offline run requested, writing an offline.config file"

  if(-not (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.2019.*.msi"}))
  {
    Write-Warning "To run tests offline, you will need a v4 (2018 or 2019) installer in the .\Tests folder"
    throw
  }

  if(-not (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.3.*.msi"}))
  {
    Write-Warning "To run tests offline, you will need a v3 installer in the .\Tests folder"
    throw
  }

  [pscustomobject]@{
      v4file = (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.2019.*.msi"} | Select-Object -first 1 | Select-Object -expand Name);
      v3file = (Get-ChildItem .\Tests | Where-Object {$_.Name -like "Octopus.3.*.msi"} | Select-Object -first 1 | Select-Object -expand Name);
  } | ConvertTo-Json | Out-File ".\Tests\offline.config"
}

function Remove-OldLogsBeforeNewRun {
  if (Test-Path "logs") {
    Remove-Item "logs" -Force -recurse | Out-Null
  }
  New-Item -ItemType Directory -Name "logs" | Out-Null

  if (Test-Path "PSScriptAnalyzer*.log") {
    Remove-Item "PSScriptAnalyzer*.log" -Force | Out-Null
  }
  if (Test-Path "vagrant*.log") {
    Remove-Item "vagrant*.log" -Force -ErrorAction SilentlyContinue | Out-Null
  }
  if (Test-Path "PesterTestResults.xml") {
    Remove-Item "PesterTestResults.xml" -Force | Out-Null
  }
}