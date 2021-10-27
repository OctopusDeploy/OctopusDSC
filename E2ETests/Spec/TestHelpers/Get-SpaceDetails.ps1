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
        $SpaceName
    )

    [PSCustomObject]$space = Get-SpaceViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -SpaceName $SpaceName
    $exists = $null -ne $space
    $description = ""
    if ($exists) {
        $description = $space.Description
    }
    return @{
        Exists = $exists;
        Description = $description;
    }
}
