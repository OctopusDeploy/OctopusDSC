function Get-SpaceDetails {
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
        $SpaceName,
        [Parameter(Mandatory=$false)]
        [string]
        $SpaceId
    )

    [PSCustomObject]$space = Get-SpaceViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceName $SpaceName -SpaceFragment $spaceFragment
    $exists = $null -ne $environment
    $description = ""
    if ($exists) {
        $description = $space.Description
    }
    return @{
        Exists = $exists;
        Description = $description;
    }
}
