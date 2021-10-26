function Get-WorkerPoolDetails {
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
        $WorkerPoolName,
        [Parameter(Mandatory=$false)]
        [string]
        $SpaceId
    )

    $serverSupportsSpaces = Test-ServerSupportsSpaces $OctopusServerUrl
    if ($serverSupportsSpaces -and (-not [string]::IsNullOrEmpty($SpaceId))) {
        $spaceFragment = "$SpaceId/"
    }

    [PSCustomObject]$workerPool = Get-WorkerPoolViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -WorkerPoolName $WorkerPoolName -SpaceFragment $spaceFragment

    return @{
        Exists = $null -ne $workerPool;
    }
}
