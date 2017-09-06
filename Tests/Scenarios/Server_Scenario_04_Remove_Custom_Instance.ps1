Configuration Server_Scenario_04_Remove_Custom_Instance
{
    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
        }

        cOctopusServer OctopusServer
        {
            Ensure = "Absent"
            State = "Stopped"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "MyOctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminUsername = "OctoAdmin"
            OctopusAdminPassword = "SuperS3cretPassw0rd!"

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false
        }
    }
}
