function Get-SpaceViaApi {
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
        $SpaceName
    )

    $url = "$OctopusServerUrl/api/spaces/all?api-key=$OctopusApiKey"
    $response = Invoke-RestMethod $url
    $space = $response | Where-Object { $_.Name -eq $SpaceName }

    return $space
}
