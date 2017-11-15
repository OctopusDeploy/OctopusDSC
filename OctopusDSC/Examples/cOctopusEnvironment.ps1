Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        $pass = ConvertTo-SecureString "Password" -AsPlainText -Force
        $creds = New-Object System.Management.Automation.PSCredential ("username", $pass)

        cOctopusEnvironment "Create 'Development' Environment"
        {
            Url = "https://octopus.example.com"
            Ensure = 'Present'
            EnvironmentName = 'Development'
            OctopusCredentials = $creds
        }
    }
}
