Configuration Server_Scenario_06_Upgrade
{
    param ($ApiKey)

    Import-DscResource -ModuleName OctopusDSC

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    $pass = ConvertTo-SecureString $ApiKey -AsPlainText -Force
    $apiCred = New-Object System.Management.Automation.PSCredential ("ignored", $pass)

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
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

            # use a new database, as old one is not removed
            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario5;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false
        }

        cOctopusEnvironment "Delete 'UAT 1' Environment"
        {
            Url = "http://localhost:81"
            Ensure = "Absent"
            OctopusApiKey = $apiCred
            EnvironmentName = "UAT 1"
        }
    }
}