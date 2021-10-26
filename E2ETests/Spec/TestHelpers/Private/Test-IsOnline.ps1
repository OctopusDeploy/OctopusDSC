function Test-IsOnline {
    [CmdletBinding()]
    [OutputType([boolean])]
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

    $machine = Invoke-PollUntilMachineHasCompletedHealthCheck -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -spaceFragment $spaceFragment
    $status = $machine.Status
    if ("$status" -eq "") {
        $status = $machine.HealthStatus
        return $status -eq "Healthy" -or $status -eq "HasWarnings"
    } else {
        return $status -eq "Online" -or $status -eq "CalamariNeedsUpgrade" -or $status -eq "NeedsUpgrade"
    }
}
