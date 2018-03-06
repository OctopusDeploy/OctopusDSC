Configuration Server_Scenario_04_Remove_Second_Node
{
    Import-DscResource -ModuleName OctopusDSC

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cOctopusServer OctopusServerSecondNode
        {
            Ensure = "Absent"
            State = "Stopped"

            Name = "HANode"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:82"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario1;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false

            HomeDirectory = "C:\ChezOctopusSecondNode"
        }
    }
}
