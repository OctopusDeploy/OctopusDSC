function Get-TentacleDetails {
    [CmdletBinding()]
    [OutputType([HashTable])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $InstanceName,
        [Parameter(Mandatory=$false)]
        [string]
        $SpaceId
    )

    [bool]$exists = Test-Path "c:\program files\Octopus Deploy\Tentacle\Tentacle.exe"
    [PSCustomObject]$machine = @{}
    [string[]]$environments = @()
    [string[]]$tenants = @()
    [string]$machinePolicy = $null
    [bool]$isOnline = $false
    [string]$communicationStyle = $Null

    if ($exists) {
        $thumbprint = Get-Thumbprint $InstanceName
        $serverSupportsSpaces = Test-ServerSupportsSpaces $OctopusServerUrl
        if ($serverSupportsSpaces) {
            $spaceFragment = "$SpaceId/"
        }
        $machine = Get-MachineViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -Thumbprint $thumbprint -SpaceFragment $spaceFragment
        $communicationStyle = $machine.Endpoint.CommunicationStyle
        $environments = (Get-Environments -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceFragment $spaceFragment) | Where-Object { $machine.EnvironmentIds -contains $_.Id } | Select-Object -ExpandProperty Name
        $tenants = (Get-Tenants -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceFragment $spaceFragment) | Where-Object { $machine.TenantIds -contains $_.Id } | Select-Object -ExpandProperty Name
        $machinePolicy = (Get-MachinePolicies -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceFragment $spaceFragment) | Where-Object { $machine.MachinePolicyId -contains $_.Id } | Select-Object -ExpandProperty Name
        $isOnline = Test-IsOnline -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -SpaceFragment $spaceFragment
    }

    return @{
        Exists = $exists;
        IsRegisteredWithTheServer = $null -ne $machine;
        IsOnline = $isOnline
        IsListening = $communicationStyle -eq "TentaclePassive"
        IsPolling = $communicationStyle -eq "TentacleActive"
        Environments = ,$environments
        Roles = $machine.Roles
        DisplayName  = $machine.Name
        Tenants = ,$tenants
        TenantTags = $machine.TenantTags
        Policy = $machinePolicy
        TenantedDeploymentParticipation = $machine.TenantedDeploymentParticipation
        Endpoint = $machine.Uri
    }
}

function Get-Thumbprint {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [string]
        $InstanceName
    )

    return "102C445D1F01C4C5957D5CFA53FF2D7CA80E84BB"

    $thumbprint = & "c:\program files\Octopus Deploy\Tentacle\Tentacle.exe" show-thumbprint --console --nologo --instance $InstanceName
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand starting ====', ''
    $thumbprint = $thumbprint -replace 'The thumbprint of this Tentacle is: ', ''
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand completed ====', ''
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand ====', ''
    return $thumbprint.Trim()
}

function Test-ServerSupportsSpaces {
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter()]
        [string]
        $OctopusServerUrl
    )

    $response = Invoke-RestMethod "$OctopusServerUrl/api/"

    return [System.Version]::Parse($response.version) -gt [System.Version]::Parse('2019.0.0')
}

function Get-MachineViaApi {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $thumbprint,
        [Parameter(Mandatory=$true)]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)machines/all?api-key=$OctopusApiKey"
    $response = Invoke-RestMethod $url
    $machine = $response | Where-Object { $_.Thumbprint -eq $thumbprint }

    return $machine
}

function Get-Environments {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)environments/all?api-key=$OctopusApiKey"
    return Invoke-RestMethod $url
}

function Get-Tenants {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)tenants/all?api-key=$OctopusApiKey"
    return Invoke-RestMethod $url
}

function Get-MachinePolicies {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)machinepolicies/all?api-key=$OctopusApiKey"
    return Invoke-RestMethod $url
}

function Test-IsOnline {
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $thumbprint,
        [Parameter(Mandatory=$true)]
        [string]
        $spaceFragment
    )

    $machine = Invoke-PollUntilMachineHasCompletedHealthCheck -OctopusServerUrl "https://matt-richardson.octopus.app" -OctopusApiKey "API-BII5ZPNWVCJQRAVEOTCRDZYFAW62BI5" -thumbprint $thumbprint -spaceFragment $spaceFragment
    $status = $machine.Status
    if ("$status" -eq "") {
        $status = $machine.HealthStatus
        return $status -eq "Healthy" -or $status -eq "HasWarnings"
    } else {
        return $status -eq "Online" -or $status -eq "CalamariNeedsUpgrade" -or $status -eq "NeedsUpgrade"
    }
}

function Invoke-PollUntilMachineHasCompletedHealthCheck {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusServerUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $OctopusApiKey,
        [Parameter(Mandatory=$true)]
        [string]
        $thumbprint,
        [Parameter(Mandatory=$true)]
        [string]
        $spaceFragment
    )

    $counter = 1

    do
    {
        $machine = Get-MachineViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -SpaceFragment $spaceFragment
        if ($null -eq $machine) { break }
        if ($counter -gt 10) { break }
        if ($machine.StatusSummary -ne "This machine was recently added. Please perform a health check.") { break }
        Write-Information "Machine health check for $($machine.Name) has not yet completed. Waiting 5 seconds to try again."
        $counter++
        Start-Sleep -seconds 5
    } while ($true)

    return $machine
}

Get-TentacleDetails -OctopusServerUrl "https://matt-richardson.octopus.app" -OctopusApiKey "API-BII5ZPNWVCJQRAVEOTCRDZYFAW62BI5" -InstanceName "Ubuntu" -SpaceId "Spaces-1"
