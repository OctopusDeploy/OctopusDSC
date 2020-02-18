
Configuration Server_Scenario_14_Install_Without_Configure
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

        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Installed"
            Name = "OctopusServer"

            # temp for testing https://github.com/OctopusDeploy/OctopusClients/pull/506
            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.13.5-octopusclientcom0056-x64.msi"
        }
    }
}