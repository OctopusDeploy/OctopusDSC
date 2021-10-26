function Get-EnvironmentDetails {
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
        $EnvironmentName,
        [Parameter(Mandatory=$false)]
        [string]
        $SpaceId
    )

    $serverSupportsSpaces = Test-ServerSupportsSpaces $OctopusServerUrl
    if ($serverSupportsSpaces -and (-not [string]::IsNullOrEmpty($SpaceId))) {
        $spaceFragment = "$SpaceId/"
    }

    [PSCustomObject]$environment = Get-EnvironmentViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -EnvironmentName $EnvironmentName -SpaceFragment $spaceFragment

    return @{
        Exists = $null -ne $environment;
    }
}
