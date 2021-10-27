function Test-IsWorkerOnline {
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

    $worker = Invoke-PollUntilWorkerHasCompletedHealthCheck -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -spaceFragment $spaceFragment
    $status = $worker.Status
    if ("$status" -eq "") {
        $status = $worker.HealthStatus
        return $status -eq "Healthy" -or $status -eq "HasWarnings"
    } else {
        return $status -eq "Online" -or $status -eq "CalamariNeedsUpgrade" -or $status -eq "NeedsUpgrade"
    }
}
