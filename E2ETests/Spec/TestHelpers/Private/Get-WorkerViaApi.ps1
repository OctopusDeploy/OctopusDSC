function Get-WorkerViaApi {
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
        [AllowEmptyString()]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)workers/all?api-key=$OctopusApiKey"
    $response = Invoke-RestMethod $url
    $worker = $response | Where-Object { $_.Thumbprint -eq $thumbprint }

    return $worker
}
