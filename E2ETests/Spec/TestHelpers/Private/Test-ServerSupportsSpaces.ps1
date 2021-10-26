function Test-ServerSupportsSpaces {
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter()]
        [string]
        $OctopusServerUrl
    )

    $response = Invoke-RestMethod "$OctopusServerUrl/api/"

    return [System.Version]::Parse($response.version) -gt [System.Version]::Parse('2019.0.0')
}
