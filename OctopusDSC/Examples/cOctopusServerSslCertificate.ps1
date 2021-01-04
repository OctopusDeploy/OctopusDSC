# Creates an environment in an Octopus Server instance

Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerSslCertificate "Bind SSL Certifiate"
        {
            InstanceName = "OctopusSErver"
            Thumbprint = "c42a148bcd3959101f2e7a3d76edb924bff84b6b"
            Ensure = "Present"
            StoreName = "My"
            Port = "443"
        }
    }
}
