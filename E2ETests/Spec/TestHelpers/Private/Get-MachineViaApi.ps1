function Get-MachineViaApi {
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
        [string]
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)machines/all?api-key=$OctopusApiKey"
    $response = Invoke-RestMethod $url
    $machine = $response | Where-Object { $_.Thumbprint -eq $thumbprint }

    return $machine
}
