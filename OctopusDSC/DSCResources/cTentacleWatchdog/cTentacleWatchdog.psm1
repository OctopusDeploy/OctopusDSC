$tentacleExePath = "$($env:ProgramFiles)\Octopus Deploy\Tentacle\Tentacle.exe"

function Get-TargetResource
{
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  [OutputType([Hashtable])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InstanceName,
    [Parameter(Mandatory)]
    [boolean]$Enabled,
    [int]$Interval = 15,
    [string]$Instances = "*"
  )
  # check octopus installed
  if (-not (Test-Path -LiteralPath $tentacleExePath)) {
    throw "Unable to find Tentacle (checked for existence of file '$tentacleExePath')."
  }
  # check octopus version >= 3.17.0
  if (-not (Test-TentacleSupportsShowConfiguration
  )) {
    throw "This resource only supports Tentacle 3.15.8+."
  }

  $config = Get-Configuration $InstanceName

  $result = @{
    InstanceName = $InstanceName
    Enabled = $config.Octopus.Watchdog.Enabled
    Interval = $config.Octopus.Watchdog.Interval
    Instances = $config.Octopus.Watchdog.Instances
  }

  return $result
}

function Set-TargetResource
{
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InstanceName,
    [Parameter(Mandatory)]
    [boolean]$Enabled,
    [int]$Interval = 15,
    [string]$Instances = "*"
  )
  if ($Enabled) {
    $args = @(
      'watchdog',
      '--create',
      '--interval', $Interval,
      '--instances', """$Instances"""
    )
  }
  else {
    $args = @(
      'watchdog',
      '--delete'
    )
  }
  Invoke-TentacleCommand $args
}

function Test-TargetResource
{
  [OutputType([boolean])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InstanceName,
    [Parameter(Mandatory)]
    [boolean]$Enabled,
    [int]$Interval = 15,
    [string]$Instances = "*"
  )
  $currentResource = (Get-TargetResource -InstanceName $InstanceName `
                                         -Enabled $Enabled `
                                         -Interval $Interval `
                                         -Instances $Instances)

  $params = Get-Parameters $MyInvocation.MyCommand.Parameters

  $currentConfigurationMatchesRequestedConfiguration = $true
  foreach($key in $currentResource.Keys)
  {
    $currentValue = $currentResource.Item($key)
    $requestedValue = $params.Item($key)
    if ($currentValue -ne $requestedValue)
    {
      Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '$currentValue' mismatched the specified value '$requestedValue'"
      $currentConfigurationMatchesRequestedConfiguration = $false
    }
    else
    {
      Write-Verbose "Configuration parameter '$key' matches the requested value '$requestedValue'"
    }
  }

  return $currentConfigurationMatchesRequestedConfiguration
}

function Get-Configuration($instanceName)
{
  $rawConfig = & $tentacleExePath show-configuration --instance $instanceName
  $config = $rawConfig | ConvertFrom-Json
  return $config
}

function Invoke-TentacleCommand ($arguments)
{
  Write-Verbose "Executing command '$tentacleExePath $($arguments -join ' ')'"
  $output = .$tentacleExePath $arguments

  Write-CommandOutput $output
  if (($null -ne $LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
    Write-Error "Command returned exit code $LASTEXITCODE. Aborting."
    exit 1
  }
  Write-Log "done."
}

function Write-CommandOutput
{
  param (
    [string] $output
  )

  if ($output -eq "") { return }

  Write-Verbose ""
  #this isn't quite working
  foreach($line in $output.Trim().Split("`n"))
  {
    Write-Verbose $line
  }
  Write-Verbose ""
}

function Test-TentacleSupportsShowConfiguration
{
  if (-not (Test-Path -LiteralPath $tentacleExePath))
  {
    throw "Tentacle.exe path '$tentacleExePath' does not exist."
  }

  $exeFile = Get-Item -LiteralPath $tentacleExePath -ErrorAction Stop
  if ($exeFile -isnot [System.IO.FileInfo])
  {
    throw "Tentacle.exe path '$tentacleExePath ' does not refer to a file."
  }

  $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($tentacleExePath).FileVersion
  $tentacleVersion = New-Object System.Version $fileVersion
  $versionWhereShowConfigurationWasIntroduced = New-Object System.Version 3, 15, 8

  return ($tentacleVersion -ge $versionWhereShowConfigurationWasIntroduced)
}

function Get-Parameters($parameters)
{
  # unfortunately $PSBoundParameters doesn't contain parameters that weren't supplied (because the default value was okay)
  # credit to https://www.briantist.com/how-to/splatting-psboundparameters-default-values-optional-parameters/
  $params = @{}
  foreach($h in $parameters.GetEnumerator()) {
    $key = $h.Key
    $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
    if ($null -ne $var)
    {
      $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
      $params[$key] = $val
    }
  }
  return $params
}
