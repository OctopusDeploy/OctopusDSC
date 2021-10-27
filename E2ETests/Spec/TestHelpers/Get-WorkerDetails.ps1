function Get-WorkerDetails {
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
    [PSCustomObject]$worker = @{}
    [bool]$isOnline = $false
    [string]$communicationStyle = $Null

    if ($exists) {
        $thumbprint = Get-Thumbprint $InstanceName
        $serverSupportsSpaces = Test-ServerSupportsSpaces $OctopusServerUrl
        if ($serverSupportsSpaces -and (-not [string]::IsNullOrEmpty($SpaceId))) {
            $spaceFragment = "$SpaceId/"
        }
        $worker = Get-WorkerViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -Thumbprint $thumbprint -SpaceFragment $spaceFragment
        $communicationStyle = $worker.Endpoint.CommunicationStyle
        $isOnline = Test-IsWorkerOnline -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -SpaceFragment $spaceFragment
    }

    return @{
        Exists = $exists;
        IsRegisteredWithTheServer = $null -ne $worker;
        IsOnline = $isOnline
        IsListening = $communicationStyle -eq "TentaclePassive"
        IsPolling = $communicationStyle -eq "TentacleActive"
        DisplayName  = $worker.Name
    }
}
