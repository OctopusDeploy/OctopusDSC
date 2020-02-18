$pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

$seqPlainTextApiKey = ConvertTo-SecureString "MyMagicSeqApiKey" -AsPlainText -Force
$seqApiKey = New-Object System.Management.Automation.PSCredential ("ignored", $seqPlainTextApiKey)

Configuration Server_Scenario_01_Install
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

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario1;Trusted_Connection=True;"

            # temp for testing https://github.com/OctopusDeploy/OctopusClients/pull/506
            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.13.5-octopusclientcom0056-x64.msi"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false

            HomeDirectory = "C:\ChezOctopus"

            LicenseKey = "PExpY2Vuc2UgU2lnbmF0dXJlPSJoUE5sNFJvYWx2T2wveXNUdC9Rak4xcC9PeVVQc0l6b0FJS282bk9VM1kzMUg4OHlqaUI2cDZGeFVDWEV4dEttdWhWV3hVSTR4S3dJcU9vMTMyVE1FUT09Ij4gICA8TGljZW5zZWRUbz5PY3RvVGVzdCBDb21wYW55PC9MaWNlbnNlZFRvPiAgIDxMaWNlbnNlS2V5PjI0NDE0LTQ4ODUyLTE1NDI3LTQxMDgyPC9MaWNlbnNlS2V5PiAgIDxWZXJzaW9uPjIuMDwhLS0gTGljZW5zZSBTY2hlbWEgVmVyc2lvbiAtLT48L1ZlcnNpb24+ICAgPFZhbGlkRnJvbT4yMDE3LTEyLTA4PC9WYWxpZEZyb20+ICAgPE1haW50ZW5hbmNlRXhwaXJlcz4yMDIzLTAxLTAxPC9NYWludGVuYW5jZUV4cGlyZXM+ICAgPFByb2plY3RMaW1pdD5VbmxpbWl0ZWQ8L1Byb2plY3RMaW1pdD4gICA8TWFjaGluZUxpbWl0PjE8L01hY2hpbmVMaW1pdD4gICA8VXNlckxpbWl0PlVubGltaXRlZDwvVXNlckxpbWl0PiA8L0xpY2Vuc2U+"
            SkipLicenseCheck = $true

            LogTaskMetrics = $true
            LogRequestMetrics = $false
        }

        cOctopusSeqLogger "Enable logging to seq"
        {
            InstanceType = "OctopusServer"
            Ensure = "Present"
            SeqServer = "http://localhost/seq"
            SeqApiKey = $seqApiKey
            Properties = @{ Application = "Octopus"; Server = "MyServer" }
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusEnvironment "Create 'Production' Environment"
        {
            Url = "http://localhost:81"
            Ensure = "Present"
            OctopusCredentials = $cred
            EnvironmentName = "Production"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerSpace "Create 'Integration Team' Space"
        {
            Url = "http://localhost:81"
            Ensure = "Present"
            OctopusCredentials = $cred
            Name = "Integration Team"
            SpaceManagersTeamMembers = @("admin")
            SpaceManagersTeams = @("Everyone")
            Description = "Description for the Integration Team Space"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusWorkerPool "Create a second workerpool"
        {
            Url = "http://localhost:81"
            Ensure = "Present"
            OctopusCredentials = $cred
            WorkerPoolName = "Secondary Worker Pool"
            WorkerPoolDescription = "A secondary worker pool to test the resource"
            SpaceId = "Spaces-1"
        }

        Script "Create Api Key and set environment variables for tests"
        {
            SetScript = {
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

                #connect
                $endpoint = new-object Octopus.Client.OctopusServerEndpoint "http://localhost:81"
                $repository = new-object Octopus.Client.OctopusRepository $endpoint

                #sign in
                $credentials = New-Object Octopus.Client.Model.LoginCommand
                $credentials.Username = "OctoAdmin"
                $credentials.Password = "SuperS3cretPassw0rd!"
                $repository.Users.SignIn($credentials)

                #create the api key
                $user = $repository.Users.GetCurrent()
                $createApiKeyResult = $repository.Users.CreateApiKey($user, "Octopus DSC Testing")

                #save it to enviornment variables for tests to use
                [environment]::SetEnvironmentVariable("OctopusServerUrl", "http://localhost:81", "User")
                [environment]::SetEnvironmentVariable("OctopusServerUrl", "http://localhost:81", "Machine")
                [environment]::SetEnvironmentVariable("OctopusApiKey", $createApiKeyResult.ApiKey, "User")
                [environment]::SetEnvironmentVariable("OctopusApiKey", $createApiKeyResult.ApiKey, "Machine")
            }
            TestScript = {
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

                #connect
                $endpoint = new-object Octopus.Client.OctopusServerEndpoint "http://localhost:81"
                $repository = new-object Octopus.Client.OctopusRepository $endpoint

                #sign in
                $credentials = New-Object Octopus.Client.Model.LoginCommand
                $credentials.Username = "OctoAdmin"
                $credentials.Password = "SuperS3cretPassw0rd!"
                $repository.Users.SignIn($credentials)

                #check if the api key exists
                $user = $repository.Users.GetCurrent()
                $apiKeys = $repository.Users.GetApiKeys($user)
                $apiKey = $apiKeys | where-object {$_.Purpose -eq "Octopus DSC Testing"}

                return $null -ne $apiKey
            }
            GetScript = {
                @{
                    Result = "" #probably bad
                }
            }
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerGuestAuthentication "Enable Guest Login"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerActiveDirectoryAuthentication "Enable Active Directory Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $true
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerAzureADAuthentication "Enable Azure AD Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://login.microsoftonline.com/b91ebf6a-84be-4c6f-97f3-32a1d0a11c8a"
            ClientID = "0272262a-b31d-4acf-8891-56e96d302018"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerOktaAuthentication "Enable Okta Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://dev-258251.oktapreview.com"
            ClientID = "752nx5basdskrsbqansE"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerGoogleAppsAuthentication "Enable GoogleApps Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            ClientID = "5743519123-1232358520259-3634528"
            HostedDomain = "https://octopus.example.com"
            DependsOn = "[cOctopusServer]OctopusServer"
        }
    }
}
