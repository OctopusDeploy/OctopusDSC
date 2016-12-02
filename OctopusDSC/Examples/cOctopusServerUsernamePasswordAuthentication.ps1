Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerUsernamePasswordAuthentication EnableUsernamePasswordAuth
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }
    }
}
