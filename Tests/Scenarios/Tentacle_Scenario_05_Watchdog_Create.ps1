Configuration Tentacle_Scenario_05_Watchdog_Create
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
            InstanceName = "PollingTentacle"
            Enabled = $True
            Interval = 10
            Instances = "*"
        }
    }
}
