
Configuration Server_Scenario_14_Install_Without_Configure
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

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
        }
    }
}