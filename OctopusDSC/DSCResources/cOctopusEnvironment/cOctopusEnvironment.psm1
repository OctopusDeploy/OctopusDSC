
function Get-TargetResource {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  [OutputType([HashTable])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [PSCredential]$OctopusCredentials
  )
  $environment = Get-Environment -Url $Url `
                                 -EnvironmentName $EnvironmentName `
                                 -OctopusCredentials $OctopusCredentials
  $existingEnsure = 'Present'
  if ($null -eq $environment) {
    $existingEnsure = 'Absent'
  }

  $result = @{
    Url = $Url;
    Ensure = $existingEnsure
    EnvironmentName = $EnvironmentName
    OctopusCredentials = $OctopusCredentials
  }

  return $result
}

function Set-TargetResource {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [PSCredential]$OctopusCredentials
  )

  $currentResource = Get-TargetResource -Url $Url `
                                        -Ensure $Ensure `
                                        -EnvironmentName $EnvironmentName `
                                        -OctopusCredentials $OctopusCredentials

  if ($Ensure -eq "Absent" -and $currentResource.Ensure -eq "Present") {
    Remove-Environment -Url $Url `
                       -EnvironmentName $EnvironmentName `
                       -OctopusCredentials $OctopusCredentials
  } elseif ($Ensure -eq "Present" -and $currentResource.Ensure -eq "Absent") {
    New-Environment -Url $Url `
                    -EnvironmentName $EnvironmentName `
                    -OctopusCredentials $OctopusCredentials

  }
}

function Test-TargetResource {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  [OutputType([boolean])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [PSCredential]$OctopusCredentials
  )
  $currentResource = (Get-TargetResource -Url $Url `
                                         -Ensure $Ensure `
                                         -EnvironmentName $EnvironmentName `
                                         -OctopusCredentials $OctopusCredentials)

  $params = Get-OctopusDSCParameter $MyInvocation.MyCommand.Parameters

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

function Remove-Environment {
  param (
    [string]$Url,
    [string]$EnvironmentName,
    [PSCredential]$OctopusCredentials
  )

  $repository = Get-OctopusClientRepository -Url $Url `
                                            -OctopusCredentials $OctopusCredentials


  $environment = $repository.Environments.FindByName($EnvironmentName)
  $repository.Environments.Delete($environment)
}

function New-Environment {
  param (
    [string]$Url,
    [string]$EnvironmentName,
    [PSCredential]$OctopusCredentials
  )
  $repository = Get-OctopusClientRepository -Url $Url `
                                          -OctopusCredentials $OctopusCredentials

  $environment = New-Object Octopus.Client.Model.EnvironmentResource
  $environment.Name = $EnvironmentName
  $repository.Environments.Create($environment) | Out-Null
}

function Get-Environment {
  param (
    [string]$Url,
    [string]$EnvironmentName,
    [PSCredential]$OctopusCredentials
  )

  $repository = Get-OctopusClientRepository -Url $Url `
                                            -OctopusCredentials $OctopusCredentials

  $environment = $repository.Environments.FindByName($EnvironmentName)
  return $environment
}

function Get-OctopusClientRepository
{
  param (
    [string]$Url,
    [string]$EnvironmentName,
    [PSCredential]$OctopusCredentials
  )

  $folder = [System.IO.Path]::GetTempPath()
  $folder = Join-Path $folder ([Guid]::NewGuid())
  New-Item -type Directory $folder | Out-Null

  Copy-Item "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll" $folder
  Copy-Item "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll" $folder

  #shadow copy these files, so we can uninstall octopus
  Add-Type -Path (Join-Path $folder "Newtonsoft.Json.dll")
  Add-Type -Path (Join-Path $folder "Octopus.Client.dll")

  #connect
  $endpoint = new-object Octopus.Client.OctopusServerEndpoint $Url
  $repository = new-object Octopus.Client.OctopusRepository $endpoint

  #sign in
  $credentials = New-Object Octopus.Client.Model.LoginCommand
  $credentials.Username = $OctopusCredentials.GetNetworkCredential().Username
  $credentials.Password = $OctopusCredentials.GetNetworkCredential().Password
  $repository.Users.SignIn($credentials)

  return $repository
}

function Get-OctopusDSCParameter($parameters) {
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
