function Get-MachinePolicies {
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
        $spaceFragment
    )

    $url = "$OctopusServerUrl/api/$($spaceFragment)machinepolicies/all?api-key=$OctopusApiKey"
    return Invoke-RestMethod $url
}
