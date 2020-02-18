$pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

Configuration Server_Scenario_15_Configure_Preinstalled_Instance
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

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
            Name = "ConfigurePreInstalledInstance"
            WebListenPrefix = "http://localhost:81"
            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario15;Trusted_Connection=True;"
            OctopusAdminCredential = $cred

            # temp for testing https://github.com/OctopusDeploy/OctopusClients/pull/506
            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.13.5-octopusclientcom0056-x64.msi"

            AllowCollectionOfUsageStatistics = $false
        }

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "ConfigurePreInstalledInstance"
            Enabled = $true
            DependsOn = "[cOctopusServer]OctopusServer"
        }
    }
}
