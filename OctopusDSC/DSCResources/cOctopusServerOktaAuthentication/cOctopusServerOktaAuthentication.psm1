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
    # check octopus version >= 3.16.0
    if (-not (Test-OctopusVersionSupportsOktaAuthenticationProvider)) {
        throw "This resource only supports Octopus Deploy 3.16.0+."
    }

    $config = Get-Configuration $InstanceName

    $result = @{
        InstanceName = $InstanceName
        Enabled      = $config.Octopus.Okta.IsEnabled
        Issuer       = $config.Octopus.Okta.Issuer
        ClientId     = $config.Octopus.Okta.ClientId
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
        '--oktaIsEnabled', $Enabled,
        '--oktaIssuer', $Issuer,
        '--oktaClientId', $ClientId
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

function Get-Configuration($instanceName) {
    $rawConfig = & $octopusServerExePath show-configuration --format=json-hierarchical --noconsolelogging --console --instance $instanceName
    $config = $rawConfig | ConvertFrom-Json
    return $config
}

function Write-CommandOutput {
    param (
        [string] $output
    )

    if ($output -eq "") { return }

    Write-Verbose ""
    #this isn't quite working
    foreach ($line in $output.Trim().Split("`n")) {
        Write-Verbose $line
    }
    Write-Verbose ""
}

function Test-OctopusVersionSupportsOktaAuthenticationProvider {
    if (-not (Test-Path -LiteralPath $octopusServerExePath)) {
        throw "Octopus.Server.exe path '$octopusServerExePath' does not exist."
    }

    $exeFile = Get-Item -LiteralPath $octopusServerExePath -ErrorAction Stop
    if ($exeFile -isnot [System.IO.FileInfo]) {
        throw "Octopus.Server.exe path '$octopusServerExePath ' does not refer to a file."
    }

    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($octopusServerExePath).FileVersion
    $octopusServerVersion = New-Object System.Version $fileVersion
    $versionWhereAuthenticationOktaProviderWasIntroduced = New-Object System.Version 3, 16, 0

    return ($octopusServerVersion -ge $versionWhereAuthenticationOktaProviderWasIntroduced)
}
