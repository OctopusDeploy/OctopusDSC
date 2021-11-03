function Invoke-PollUntilWorkerHasCompletedHealthCheck {
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

    $counter = 1

    do
    {
        $worker = Get-WorkerViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -SpaceFragment $spaceFragment
        if ($null -eq $worker) { break }
        if ($counter -gt 10) { break }
        if ($worker.StatusSummary -ne "This machine was recently added. Please perform a health check.") { break }
        Write-Information "Machine health check for $($worker.Name) has not yet completed. Waiting 5 seconds to try again."
        $counter++
        Start-Sleep -seconds 5
    } while ($true)

    return $worker
}

