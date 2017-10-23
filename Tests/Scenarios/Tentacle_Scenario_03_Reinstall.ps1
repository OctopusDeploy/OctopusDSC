Configuration Tentacle_Scenario_03_Reinstall
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles)

    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
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

            TentacleDownloadUrl64 = $downloadUrl

            # Optional settings
            ListenPort = 10933;
            DefaultApplicationDirectory = "C:\Applications"
            #TentacleDownloadUrl = "https://download.octopusdeploy.com/octopus/Octopus.Tentacle.3.3.24.msi"
            #TentacleDownloadUrl64 = "https://download.octopusdeploy.com/octopus/Octopus.Tentacle.3.3.24-x64.msi"
            PublicHostNameConfiguration = "ComputerName"
            TentacleHomeDirectory = "C:\Octopus\OctopusTentacleHome"
        }
    }
}
