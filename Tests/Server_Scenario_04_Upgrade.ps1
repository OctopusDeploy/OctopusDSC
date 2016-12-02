Configuration Server_Scenario_04_Upgrade
{
    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Started"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            # use a new database, as old one is not removed
            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusDeploy;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminUsername = "OctoAdmin"
            OctopusAdminPassword = "SuperS3cretPassw0rd!"

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false
        }
    }
}
