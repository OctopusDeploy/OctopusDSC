$config = get-content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
$OctopusServerUrl = $config.OctopusServerUrl
$ApiKey = $config.OctopusApiKey
$Environments = "The-Env"
$Roles = "Test-Tentacle"
$ServerThumbprint = $config.OctopusServerThumbprint

Configuration Tentacle_Scenario_02_Remove
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        # cOctopusSeqLogger "Disable logging to seq"
        # {
        #     InstanceType = 'Tentacle'
        #     Ensure = 'Absent'
        # }

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
            DependsOn = "[cOctopusSeqLogger]Disable logging to seq"
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
            Environments = "Env2";
            Roles = $Roles;

            # Optional settings
            ServerPort = 10943;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Poll"
            TentacleHomeDirectory = "C:\Octopus\PollingTentacleHome"
            DependsOn = "[cOctopusSeqLogger]Disable logging to seq"
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
            DependsOn = "[cOctopusSeqLogger]Disable logging to seq"
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
            DependsOn = "[cOctopusSeqLogger]Disable logging to seq"
        }

        cTentacleAgent WorkerTentacle
        {
            Ensure = "Absent";
            State = "Stopped";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "WorkerTentacle";

            DisplayName = "My Worker Tentacle"

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Roles = $Roles;

            # Optional settings
            ListenPort = 10937;
            DefaultApplicationDirectory = "C:\Applications"
            PublicHostNameConfiguration = "ComputerName"
            TentacleHomeDirectory = "C:\Octopus\WorkerTentacleHome"

            WorkerPools = @("Secondary Worker Pool")
        }


        cTentacleAgent ListeningTentacleWithCustomAccount
        {
            Ensure = "Absent";
            State = "Stopped";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacleWithCustomAccount";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = 10936;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Listen"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithCustomAccountHome"

            TentacleServiceCredential = $serviceusercredential
            DependsOn = "[cOctopusSeqLogger]Disable logging to seq"
        }
    }
}
