Configuration Server_Scenario_03_Install_Custom_Instance
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

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "MyOctopusServer"
            Enabled = $true
        }

        cOctopusServerActiveDirectoryAuthentication "Enable Active Directory Auth"
        {
            InstanceName = "MyOctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $true
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
        }

        cOctopusServerAzureADAuthentication "Enable Azure AD Auth"
        {
            InstanceName = "MyOctopusServer"
            Enabled = $true
            Issuer = "https://login.microsoftonline.com/b91ebf6a-84be-4c6f-97f3-32a1d0a11c8a"
            ClientID = "0272262a-b31d-4acf-8891-56e96d302018"
        }

        cOctopusServerGoogleAppsAuthentication "Enable GoogleApps Auth"
        {
            InstanceName = "MyOctopusServer"
            Enabled = $true
            ClientID = "5743519123-1232358520259-3634528"
            HostedDomain = "https://octopus.example.com"
        }
    }
}
