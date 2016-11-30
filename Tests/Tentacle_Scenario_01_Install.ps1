Configuration Tentacle_Scenario_01_Install
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles, $ListenPort)

    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        cTentacleAgent ListeningTentacle
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacle";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = $ListenPort;
            DefaultApplicationDirectory = "C:\Applications"
            PublicHostNameConfiguration = "ComputerName"
        }

        cTentacleAgent PollingTentacle
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "PollingTentacle";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = $ListenPort;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Poll"
        }
    }
}
