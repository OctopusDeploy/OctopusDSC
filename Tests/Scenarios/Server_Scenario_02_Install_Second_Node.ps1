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

            # temp for testing https://github.com/OctopusDeploy/OctopusClients/pull/506
            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.13.5-octopusclientcom0056-x64.msi"

            OctopusMasterKey = $MasterKeyCred

            # The admin user to create
            OctopusAdminCredential = $cred

            # Don't clash the comms port
            ListenPort = 10935

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false

            HomeDirectory = "C:\ChezOctopusSecondNode"

            LicenseKey = "PExpY2Vuc2UgU2lnbmF0dXJlPSJoUE5sNFJvYWx2T2wveXNUdC9Rak4xcC9PeVVQc0l6b0FJS282bk9VM1kzMUg4OHlqaUI2cDZGeFVDWEV4dEttdWhWV3hVSTR4S3dJcU9vMTMyVE1FUT09Ij4gICA8TGljZW5zZWRUbz5PY3RvVGVzdCBDb21wYW55PC9MaWNlbnNlZFRvPiAgIDxMaWNlbnNlS2V5PjI0NDE0LTQ4ODUyLTE1NDI3LTQxMDgyPC9MaWNlbnNlS2V5PiAgIDxWZXJzaW9uPjIuMDwhLS0gTGljZW5zZSBTY2hlbWEgVmVyc2lvbiAtLT48L1ZlcnNpb24+ICAgPFZhbGlkRnJvbT4yMDE3LTEyLTA4PC9WYWxpZEZyb20+ICAgPE1haW50ZW5hbmNlRXhwaXJlcz4yMDIzLTAxLTAxPC9NYWludGVuYW5jZUV4cGlyZXM+ICAgPFByb2plY3RMaW1pdD5VbmxpbWl0ZWQ8L1Byb2plY3RMaW1pdD4gICA8TWFjaGluZUxpbWl0PjE8L01hY2hpbmVMaW1pdD4gICA8VXNlckxpbWl0PlVubGltaXRlZDwvVXNlckxpbWl0PiA8L0xpY2Vuc2U+"

            ArtifactsDirectory = "C:\ChezOctopus\Artifacts"
            PackagesDirectory = "C:\ChezOctopus\Packages"
            TaskLogsDirectory = "C:\ChezOctopus\TaskLogs"
        }
    }
}