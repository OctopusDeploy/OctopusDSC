function Get-WorkerPoolViaApi {
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
        $WorkerPoolName,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)workerpools/all?api-key=$OctopusApiKey"
    $response = Invoke-RestMethod $url
    $workerPool = $response | Where-Object { $_.Name -eq $WorkerPoolName }

    return $workerPool
}
