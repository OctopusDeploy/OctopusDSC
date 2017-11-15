# deserialize a password from disk.
$password = Get-Content .\ExamplePassword.txt | ConvertTo-SecureString
$ServiceCred = New-Object PSCredential "ServiceUser", $password 

Configuration SampleConfig
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort)

    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Started"

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"

            # Registration - all parameters required
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = $Environments
            Roles = $Roles

            # How Tentacle will communicate with the server
            CommunicationMode = "Listen"
            ListenPort = $ListenPort

            TentacleServiceCredential = $ServiceCred

            # Only required if the external port is different to the ListenPort. e.g the tentacle is behind a loadbalancer
            TentacleCommsPort = 10900

            # Where deployed applications will be installed by Octopus
            DefaultApplicationDirectory = "C:\Applications"

            # Where Octopus should store its working files, logs, packages etc
            TentacleHomeDirectory = "C:\Octopus"
        }
    }
}
