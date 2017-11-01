Configuration Server_Scenario_08_Watchdog_Delete
{
    Import-DscResource -ModuleName OctopusDSC

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
