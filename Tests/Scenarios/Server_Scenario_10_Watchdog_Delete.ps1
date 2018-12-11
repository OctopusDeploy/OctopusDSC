Configuration Server_Scenario_10_Watchdog_Delete
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

        cOctopusServerWatchdog OctopusServerWatchdog
        {
            InstanceName = "OctopusServer"
            Enabled = $false
        }
    }
}