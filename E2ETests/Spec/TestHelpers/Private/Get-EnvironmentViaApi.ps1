function Get-EnvironmentViaApi {
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
        $EnvironmentName,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)environments/all?api-key=$OctopusApiKey"
    $response = Invoke-RestMethod $url
    $environment = $response | Where-Object { $_.Name -eq $EnvironmentName }

    return $environment
}
