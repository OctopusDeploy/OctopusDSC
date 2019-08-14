# Configures a listening tentacle and automatically registers it with the specified server
# please see https://github.com/OctopusDeploy/OctopusDSC/blob/master/README-cTentacleAgent.md for all available options

# use password from disk
$password = Get-Content .\ExamplePassword.txt | ConvertTo-SecureString
$ServiceCred = New-Object PSCredential "ServiceUser", $password

Configuration SampleConfig
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort, $Space)

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

            OctopusServerUrl = $OctopusServerUrl
            ApiKey = $ApiKey
            Environments = $Environments
            Roles = $Roles
            Space = $Space # This is for versions 2019.1 and above.  If null or not specified, it uses the space designated as Default

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
