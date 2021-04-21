# dot-source the helper file (cannot load as a module due to scope considerations)
. (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'OctopusDSCHelpers.ps1')

# This is the Octopus Deploy server Application ID, declared within Octopus Server itself
$octopusServerApplicationId = "{E2096A4C-2391-4BE1-9F17-E353F930E7F1}"

function Get-CurrentSSLBinding {
    param([string] $ApplicationId,
    [string]$Port)

    $certificateBindings = (& netsh http show sslcert) | select-object -skip 3 | out-string
    $newLine = [System.Environment]::NewLine
    $certificateBindings = $certificateBindings -split "$newLine$newLine"
    $certificateBindingsList = foreach ($certificateBinding in $certificateBindings) {
        if ($certificateBinding -ne "") {
            $certificateBinding = $certificateBinding -replace "  ", "" -split ": "
            [pscustomobject]@{
                IPPort                = ($certificateBinding[1] -split "`n")[0]
                CertificateThumbprint = ($certificateBinding[2] -split "`n" -replace '[^a-zA-Z0-9]', '')[0]
                AppID                 = ($certificateBinding[3] -split "`n")[0]
                CertStore             = ($certificateBinding[4] -split "`n")[0]
            }
        }
    }

    return ($certificateBindingsList | Where-Object {($_.AppID.Trim() -eq $ApplicationId) -and ($_.IPPort.Trim() -eq "{0}:{1}" -f "0.0.0.0", $Port) })
}

function Get-TargetResource {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    param (
        [Parameter(Mandatory)]
        [string] $InstanceName,
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Thumbprint,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $StoreName,
        [ValidateNotNullOrEmpty()]
        [int] $Port = 443
    )

    $existingSSLConfig = (Get-CurrentSSLBinding -ApplicationId $octopusServerApplicationId -Port $Port -IPAddress $IPAddress)

    if ($null -ne $existingSSLConfig) {
        $existingSSLPort = [int](($existingSSLConfig.IPPort).Split(":")[1])
        $existingSSLThumbprint = $existingSSLConfig.CertificateThumbprint.Trim()
        $existingSSLCertificateStoreName = $existingSSLConfig.CertStore.Trim()
        $existingEnsure = "Present"
    }
    else {
        $existingEnsure = "Absent"
    }

    $result = @{
        InstanceName    = $InstanceName
        Ensure          = $existingEnsure
        Port            = $existingSSLPort
        StoreName       = $existingSSLCertificateStoreName
        Thumbprint      = $existingSSLThumbprint
    }

    return $result
}

function Test-TargetResource {
    param(
        [Parameter(Mandatory)]
        [string] $InstanceName,
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Thumbprint,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $StoreName,
        [ValidateNotNullOrEmpty()]
        [int] $Port = 443
    )

    $currentResource = (Get-TargetResource @PSBoundParameters)
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

function Set-TargetResource {
    param(
        [Parameter(Mandatory)]
        [string] $InstanceName,
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Thumbprint,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $StoreName,
        [ValidateNotNullOrEmpty()]
        [int] $Port = 443
    )

    if ($Ensure -eq "Present") {
        $exeArgs = @(
            'ssl-certificate',
            '--instance', $Instancename,
            '--thumbprint', $Thumbprint,
            '--certificate-store', $StoreName,
            '--port', $Port
        )

        Write-Verbose "Binding certificate ..."
        Invoke-OctopusServerCommand $exeArgs
    }
    else {
        $currentBinding = (Get-CurrentSSLBinding -ApplicationId $octopusServerApplicationId -Port $Port -IPAddress $IPAddress)
        if ($null -ne $currentBinding) {
            Write-Verbose "Removing certificate binding ..."
            # ideally, we'd call a command in Octopus.Server for this, but there's no command to do this (at this point)
            & netsh http delete sslcert ("{0}:{1}" -f "0.0.0.0", $Port)
            $currentBinding = (Get-CurrentSSLBinding -ApplicationId $octopusServerApplicationId -Port $Port -IPAddress $IPAddress)

            if ($null -eq $currentBinding) {
                Write-Verbose "Binding successfully removed."
            }
        }
    }
}
