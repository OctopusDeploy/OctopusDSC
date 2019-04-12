Configuration Server_Scenario_08_Upgrade
{
    param ($ApiKey)

    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    Write-Output "Using ApiKey $ApiKey" # debugging an intermittent issue in Scenario_08 throwing exception 'Cannot bind argument to parameter 'String' because it is null'

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
            AllowCollectionOfUsageStatistics = $false

            SkipLicenseCheck = $true
        }

        cOctopusEnvironment "Delete 'UAT 1' Environment"
        {
            Url = "http://localhost:81"
            Ensure = "Absent"
            OctopusApiKey = $apiCred
            EnvironmentName = "UAT 1"
            DependsOn = "[cOctopusServer]OctopusServer"
        }
    }
}
