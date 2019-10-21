$config = get-content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
$OctopusServerUrl = $config.OctopusServerUrl
$ApiKey = $config.OctopusApiKey
$Environments = "The-Env"
$Roles = Test-Tentacle

Configuration Tentacle_Scenario_03_Reinstall
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
            TentacleDownloadUrl = "https://download.octopusdeploy.com/octopus/Octopus.Tentacle.3.20.0.msi"
            TentacleDownloadUrl64 = "https://download.octopusdeploy.com/octopus/Octopus.Tentacle.3.20.0-x64.msi"
            PublicHostNameConfiguration = "ComputerName"
            TentacleHomeDirectory = "C:\Octopus\OctopusTentacleHome"
        }
    }
}
