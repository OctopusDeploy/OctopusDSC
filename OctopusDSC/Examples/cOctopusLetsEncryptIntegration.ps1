Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusLetsEncryptIntegration "Enable Let's Encrypt"
        {
            Ensure                   = "Present"
            ApiKey                   = "abc123"
            DnsName                  = "example.octopus.com"
            IpAddress                = "0.0.0.0"
            HttpsPort                = 443
            VirtualDirectory         = "/"
            RegistrationEmailAddress = "example@octopus.com"
            AcceptTos                = $true
        }
    }
}
