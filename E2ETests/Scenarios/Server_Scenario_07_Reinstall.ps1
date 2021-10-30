# reinstall an older version

Configuration Server_Scenario_07_Reinstall
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
            Ensure = "Present"
            State = "Started"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario5;Trusted_Connection=True;"

            # LegacyWebAuthenticationMode = "UsernamePassword"

            # The admin user to create
            OctopusAdminCredential = $cred

            DownloadUrl = "https://download.octopusdeploy.com/octopus/Octopus.2018.12.1-x64.msi"

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false
        }

        cOctopusServerUsernamePasswordAuthentication "EnableUsernamePasswordAuth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        #hack until https://github.com/OctopusDeploy/Issues/issues/7113 is resolved
        Script "SleepForABitToWorkaroundServerBug"
        {
            SetScript = {
                Start-Sleep -seconds 120
                Set-Content c:\temp\SleepAfterInstallHasHappened_Server_Scenario_07_Reinstall.txt -value "true"
            }
            TestScript = {
                return Test-Path c:\temp\SleepAfterInstallHasHappened_Server_Scenario_07_Reinstall.txt
            }
            GetScript = {
                @{
                    Result = Test-Path c:\temp\SleepAfterInstallHasHappened_Server_Scenario_07_Reinstall.txt
                }
            }
            DependsOn = "[cOctopusServerUsernamePasswordAuthentication]EnableUsernamePasswordAuth"
        }

        cOctopusEnvironment "Create 'UAT 1' Environment"
        {
            Url = "http://localhost:81"
            Ensure = "Present"
            OctopusCredentials = $cred
            EnvironmentName = "UAT 1"
            DependsOn = "[Script]SleepForABitToWorkaroundServerBug"
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

                write-verbose "setting OctopusApiKey to $($createApiKeyResult.ApiKey)"

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
    }
}
