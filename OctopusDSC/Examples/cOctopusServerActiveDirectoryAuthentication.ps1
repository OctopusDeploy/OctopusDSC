Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerActiveDirectoryAuthentication "Enable AD authentication"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $false
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
        }
    }
}
