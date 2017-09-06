Configuration Tentacle_Scenario_02_Remove
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles, $ServerThumbprint)

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
            ListenPort = 10933;
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
            ServerPort = 10943;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Poll"
            TentacleHomeDirectory = "C:\Octopus\PollingTentacleHome"
        }

        cTentacleAgent ListeningTentacleWithoutAutoRegister
        {
            Ensure = "Absent";
            State = "Stopped";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacleWithoutAutoRegister";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;

            # Optional settings
            ListenPort = 10934;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Poll"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithoutAutoRegisterHome"

            RegisterWithServer = $false
        }

        cTentacleAgent ListeningTentacleWithThumbprintWithoutAutoRegister
        {
            Ensure = "Absent";
            State = "Stopped";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacleWithThumbprintWithoutAutoRegister";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;

            # Optional settings
            ListenPort = 10935;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Poll"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome"

            RegisterWithServer = $false
            OctopusServerThumbprint = $ServerThumbprint
        }
    }
}
