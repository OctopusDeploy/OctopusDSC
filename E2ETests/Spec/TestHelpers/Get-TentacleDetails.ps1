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
        if ($serverSupportsSpaces -and (-not [string]::IsNullOrEmpty($SpaceId))) {
            $spaceFragment = "$SpaceId/"
        }
        $machine = Get-MachineViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -Thumbprint $thumbprint -SpaceFragment $spaceFragment
        $communicationStyle = $machine.Endpoint.CommunicationStyle
        $environments = (Get-Environments -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceFragment $spaceFragment) | Where-Object { $machine.EnvironmentIds -contains $_.Id } | Select-Object -ExpandProperty Name
        $tenants = (Get-Tenants -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceFragment $spaceFragment) | Where-Object { $machine.TenantIds -contains $_.Id } | Select-Object -ExpandProperty Name
        $machinePolicy = (Get-MachinePolicies -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceFragment $spaceFragment) | Where-Object { $machine.MachinePolicyId -contains $_.Id } | Select-Object -ExpandProperty Name
        $isOnline = Test-IsTentacleOnline -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -SpaceFragment $spaceFragment
    }

    return @{
        Exists = $exists;
        IsRegisteredWithTheServer = $null -ne $machine;
        IsOnline = $isOnline
        IsListening = $communicationStyle -eq "TentaclePassive"
        IsPolling = $communicationStyle -eq "TentacleActive"
        Environments = $environments
        Roles = $machine.Roles
        DisplayName  = $machine.Name
        Tenants = $tenants
        TenantTags = $machine.TenantTags
        Policy = $machinePolicy
        TenantedDeploymentParticipation = $machine.TenantedDeploymentParticipation
        Endpoint = $machine.Uri
    }
}
