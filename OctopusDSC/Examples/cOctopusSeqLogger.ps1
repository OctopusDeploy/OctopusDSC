Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        $pass = ConvertTo-SecureString "Password" -AsPlainText -Force
        $apiKeyCreds = New-Object System.Management.Automation.PSCredential ("ignored", $pass)

        cOctopusSeqLogger "Enable Logging to Seq for Octopus Server"
        {
            InstanceType = "OctopusServer"
            Ensure = 'Present'
            SeqServer = 'https://seq.example.com'
            SeqApiKey = $apiKeyCreds
            Properties = @{ Application = 'Octopus'; 'ApplicationSet' = 'BuildAndDeploy' }
        }
    }
}
