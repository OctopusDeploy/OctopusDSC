Configuration Scenario_00_Install_Server
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

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusDeploy;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminUsername = "Admin"
            OctopusAdminPassword = "SuperS3cretPassw0rd"
        }
    }
}
