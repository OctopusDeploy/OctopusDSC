Function Get-TargetResource
{
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Name,
        [string]$Description,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Url,
        [PSCredential]$OctopusCredentials = [PSCredential]::Empty,
        [PSCredential]$OctopusApiKey = [PSCredential]::Empty,

        [string]$SubscriptionNumber,
        [string]$CertificateBytes,
        [string]$CertificateThumbprint,
        [String]$ServiceManagementEndpointBaseUri,
        [string]$ServiceManagementEndpointSuffix,

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
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Name,
        [string]$Description,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Url,
        [PSCredential]$OctopusCredentials = [PSCredential]::Empty,
        [PSCredential]$OctopusApiKey = [PSCredential]::Empty,

        [string]$SubscriptionNumber,
        [string]$CertificateBytes,
        [string]$CertificateThumbprint,
        [String]$ServiceManagementEndpointBaseUri,
        [string]$ServiceManagementEndpointSuffix,

        [string[]]$Environments,
        [string[]]$Tenants,
        [string[]]$TenantTags,
        [ValidateSet("Untenanted","TenantedOrUntenanted","Tenanted")]
        [string]$TenantedDeploymentParticipation,
        [string]$SpaceId
    )


}

Function Test-TargetResource
{
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Name,
        [string]$Description,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Url,
        [PSCredential]$OctopusCredentials = [PSCredential]::Empty,
        [PSCredential]$OctopusApiKey = [PSCredential]::Empty,

        [string]$SubscriptionNumber,
        [string]$CertificateBytes,
        [string]$CertificateThumbprint,
        [String]$ServiceManagementEndpointBaseUri,
        [string]$ServiceManagementEndpointSuffix,

        [string[]]$Environments,
        [string[]]$Tenants,
        [string[]]$TenantTags,
        [ValidateSet("Untenanted","TenantedOrUntenanted","Tenanted")]
        [string]$TenantedDeploymentParticipation,
        [string]$SpaceId
    )


}
