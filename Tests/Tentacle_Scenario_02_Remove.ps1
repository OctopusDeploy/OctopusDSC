Configuration Tentacle_Scenario_02_Remove
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles, $ListenPort)

    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
        }

        cTentacleAgent ListeningTentacle
        {
            Ensure = "Absent";
            State = "Stopped";

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
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleHome"
        }

        cTentacleAgent PollingTentacle
        {
            Ensure = "Absent";
            State = "Stopped";

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
            TentacleHomeDirectory = "C:\Octopus\PollingTentacleHome"
        }
    }
}
