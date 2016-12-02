Configuration Server_Scenario_01_Install
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

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminUsername = "OctoAdmin"
            OctopusAdminPassword = "SuperS3cretPassw0rd!"

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false
        }

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }

        cOctopusServerActiveDirectoryAuthentication "Enable Active Directory Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $false
            AllowFormsAuthenticationForDomainUsers = $true
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
        }
    }
}
