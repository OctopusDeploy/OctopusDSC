Configuration Tentacle_Scenario_06_Watchdog_Delete
{
    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cTentacleWatchdog TentacleWatchdog
        {
            InstanceName = "Tentacle"
            Enabled = $false
        }
    }
}
