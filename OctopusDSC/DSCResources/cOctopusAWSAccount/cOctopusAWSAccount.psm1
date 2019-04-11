# dot-source the helper file (cannot load as a module due to scope considerations)
. (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'OctopusDSCHelpers.ps1')

Function Get-TargetResource
{
    # TODO: Add parameters here
    # Make sure to use the same parameters for
    # Get-TargetResource, Set-TargetResource, and Test-TargetResource
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = 'Present',
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Name,
        [string]$Description,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Url,
        [PSCredential]$OctopusCredentials = [PSCredential]::Empty,
        [PSCredential]$OctopusApiKey = [PSCredential]::Empty,
        [PSCredential]$AWSKeyPair = [PSCredential]::Empty,
        [string[]]$Environments,
        [string[]]$Tenants,
        [string[]]$TenantTags,
        [ValidateSet("Untenanted","TenantedOrUntenanted","Tenanted")]
        [string]$TenantedDeploymentParticipation,
        [string]$SpaceId
    )
}

Function Set-TargetResource
{
    # TODO: Add parameters here
    # Make sure to use the same parameters for
    # Get-TargetResource, Set-TargetResource, and Test-TargetResource
    param(
    )
}

Function Test-TargetResource
{
    # TODO: Add parameters here
    # Make sure to use the same parameters for
    # Get-TargetResource, Set-TargetResource, and Test-TargetResource
    param(
    )
}
