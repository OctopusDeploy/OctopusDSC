Configuration Server_Scenario_09_Watchdog_Create
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
            Enabled = $True
            Interval = 10
            Instances = "*"
        }
    }
}