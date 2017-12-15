$octopusServerExePath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"

# dot-source the helper file (cannot load as a module due to scope considerations)
. (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'OctopusDSCHelpers.ps1') 

function Get-TargetResource {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceName,
        [Parameter(Mandatory)]
        [boolean]$Enabled,
        [Parameter(Mandatory)]
        [string]$Issuer,
        [Parameter(Mandatory)]
        [string]$ClientId
    )
    # check octopus installed
    if (-not (Test-Path -LiteralPath $octopusServerExePath)) {
        throw "Unable to find Octopus (checked for existence of file '$octopusServerExePath')."
    }
    # check octopus version >= 3.5.0
    if (-not (Test-OctopusVersionSupportsAuthenticationProvider)) {
        throw "This resource only supports Octopus Deploy 3.5.0+."
    }

    $config = Get-ServerConfiguration $InstanceName

    $result = @{
        InstanceName = $InstanceName
        Enabled      = $config.Octopus.AzureAD.IsEnabled
        Issuer       = $config.Octopus.AzureAD.Issuer
        ClientId     = $config.Octopus.AzureAD.ClientId
    }

    return $result
}

function Set-TargetResource {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceName,
        [Parameter(Mandatory)]
        [boolean]$Enabled,
        [Parameter(Mandatory)]
        [string]$Issuer,
        [Parameter(Mandatory)]
        [string]$ClientId
    )
    $args = @(
        'configure',
        '--console',
        '--instance', $InstanceName,
        '--azureADIsEnabled', $Enabled,
        '--azureADIssuer', $Issuer,
        '--azureADClientId', $ClientId
    )
    Invoke-OctopusServerCommand $args
}

function Test-TargetResource {
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceName,
        [Parameter(Mandatory)]
        [boolean]$Enabled,
        [Parameter(Mandatory)]
        [string]$Issuer,
        [Parameter(Mandatory)]
        [string]$ClientId
    )
    $currentResource = (Get-TargetResource -InstanceName $InstanceName `
            -Enabled $Enabled `
            -Issuer $Issuer `
            -ClientId $ClientId)

    $params = Get-ODSCParameter $MyInvocation.MyCommand.Parameters

    $currentConfigurationMatchesRequestedConfiguration = $true
    foreach ($key in $currentResource.Keys) {
        $currentValue = $currentResource.Item($key)
        $requestedValue = $params.Item($key)
        if ($currentValue -ne $requestedValue) {
            Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '$currentValue' mismatched the specified value '$requestedValue'"
            $currentConfigurationMatchesRequestedConfiguration = $false
        }
        else {
            Write-Verbose "Configuration parameter '$key' matches the requested value '$requestedValue'"
        }
    }

    return $currentConfigurationMatchesRequestedConfiguration
}
function Test-OctopusVersionSupportsAuthenticationProvider {
    if (-not (Test-Path -LiteralPath $octopusServerExePath)) {
        throw "Octopus.Server.exe path '$octopusServerExePath' does not exist."
    }

    $exeFile = Get-Item -LiteralPath $octopusServerExePath -ErrorAction Stop
    if ($exeFile -isnot [System.IO.FileInfo]) {
        throw "Octopus.Server.exe path '$octopusServerExePath ' does not refer to a file."
    }

    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($octopusServerExePath).FileVersion
    $octopusServerVersion = New-Object System.Version $fileVersion
    $versionWhereAuthenticationProvidersWereIntroduced = New-Object System.Version 3, 5, 0

    return ($octopusServerVersion -ge $versionWhereAuthenticationProvidersWereIntroduced)
}

function Get-ODSCParameter($parameters) {
    # unfortunately $PSBoundParameters doesn't contain parameters that weren't supplied (because the default value was okay)
    # credit to https://www.briantist.com/how-to/splatting-psboundparameters-default-values-optional-parameters/
    $params = @{}
    foreach ($h in $parameters.GetEnumerator()) {
        $key = $h.Key
        $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
        if ($null -ne $var) {
            $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
            $params[$key] = $val
        }
    }
    return $params
}
