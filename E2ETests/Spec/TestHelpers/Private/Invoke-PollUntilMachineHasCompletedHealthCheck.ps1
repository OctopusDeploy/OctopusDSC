function Invoke-PollUntilMachineHasCompletedHealthCheck {
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
        $machine = Get-MachineViaApi -OctopusServerUrl $OctopusServerUrl -OctopusApiKey $OctopusApiKey -thumbprint $thumbprint -SpaceFragment $spaceFragment
        if ($null -eq $machine) { break }
        if ($counter -gt 10) { break }
        if ($machine.StatusSummary -ne "This machine was recently added. Please perform a health check.") { break }
        Write-Information "Machine health check for $($machine.Name) has not yet completed. Waiting 5 seconds to try again."
        $counter++
        Start-Sleep -seconds 5
    } while ($true)

    return $machine
}

