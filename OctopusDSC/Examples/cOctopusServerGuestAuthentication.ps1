Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerGuestAuthentication "Enable Guest Authentication"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }
    }
}
