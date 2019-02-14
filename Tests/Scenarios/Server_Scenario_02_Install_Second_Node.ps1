$pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

Push-Location "$env:programfiles\Octopus Deploy\Octopus"
$MasterKey = .\octopus.server.exe show-master-key --instance=OctopusServer
Pop-Location
$SecureMasterKey = ConvertTo-SecureString $MasterKey -AsPlainText -Force
$MasterKeyCred = New-Object System.Management.Automation.PSCredential  ("notused", $SecureMasterKey)

Configuration Server_Scenario_02_Install_Second_Node
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

        cOctopusServer OctopusServerSecondNode
        {
            Ensure = "Present"
            State = "Started"

            Name = "HANode"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:82"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario1;Trusted_Connection=True;"

            OctopusMasterKey = $MasterKeyCred

            # The admin user to create
            OctopusAdminCredential = $cred

            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.1.0-enh-reg-be-gone-3413-x64.msi"

            # Don't clash the comms port
            ListenPort = 10935

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false

            HomeDirectory = "C:\ChezOctopusSecondNode"

            ArtifactsDirectory = "C:\ChezOctopus\Artifacts"
            PackagesDirectory = "C:\ChezOctopus\Packages"
            TaskLogsDirectory = "C:\ChezOctopus\TaskLogs"
        }
    }
}