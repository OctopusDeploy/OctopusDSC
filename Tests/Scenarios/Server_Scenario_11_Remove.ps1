Configuration Server_Scenario_11_Remove
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cOctopusServer OctopusServer
        {
            Ensure = "Absent"
            State = "Stopped"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario5;Trusted_Connection=True;"

            # temp for testing https://github.com/OctopusDeploy/OctopusClients/pull/506
            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.13.5-octopusclientcom0056-x64.msi"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false

        }
    }
}