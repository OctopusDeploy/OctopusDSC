Configuration Server_Scenario_03_Reinstall
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
            Ensure = "Present"
            State = "Started"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusDeploy;Trusted_Connection=True;"

            LegacyWebAuthenticationMode = "UsernamePassword"

            # The admin user to create
            OctopusAdminUsername = "OctoAdmin"
            OctopusAdminPassword = "SuperS3cretPassw0rd!"

            DownloadUrl = "https://download.octopusdeploy.com/octopus/Octopus.3.3.24-x64.msi"

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false
        }
    }
}
