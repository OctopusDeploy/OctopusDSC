$config = get-content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
$OctopusServerUrl = $config.OctopusServerUrl
$ApiKey = $config.OctopusApiKey
$Environments = "The-Env"
$Roles = Test-Tentacle
$ServerThumbprint = $config.OctopusServerThumbprint

Configuration Tentacle_Scenario_04_Upgrade
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

        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = 10933;
            DefaultApplicationDirectory = "C:\Applications"
            PublicHostNameConfiguration = "ComputerName"
            TentacleHomeDirectory = "C:\Octopus\OctopusTentacleHome"
        }
    }
}
