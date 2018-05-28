
Configuration Server_Scenario_12_Built_In_Worker
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    $svcpass = ConvertTo-SecureString "HyperS3cretPassw0rd!" -AsPlainText -Force
    $svccred = New-Object System.Management.Automation.PSCredential (($env:computername + "\OctoSquid"), $svcpass)

    $runAsPass = ConvertTo-SecureString "ModeratelyS3cretPassw0rd!" -AsPlainText -Force
    # 2 different creds are required until https://github.com/OctopusDeploy/Issues/issues/4302 is fixed
    $runAsCredWithMachineName = New-Object System.Management.Automation.PSCredential (($env:computername + "\OctoMollusc"), $runAsPass)
    $runAsCred = New-Object System.Management.Automation.PSCredential ("OctoMollusc", $runAsPass)

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        User OctoSquid
        {
            Ensure = "Present"
            UserName = "OctoSquid"
            Password = $svccred
            PasswordChangeRequired = $false
        }

        Group AddUserToLocalAdminGroup
        {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= ".\OctoSquid"
            DependsOn = "[User]OctoSquid"
        }

        User OctoMollusc
        {
            Ensure = "Present"
            UserName = "OctoMollusc"
            Password = $runAsCredWithMachineName
            PasswordChangeRequired = $false
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

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=OctopusScenario10;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false

            DownloadUrl = "https://download.octopusdeploy.com/octopus/Octopus.2018.1.0-x64.msi"

            OctopusServiceCredential = $svccred

            OctopusBuiltInWorkerCredential = $runAsCred

            DependsOn = @("[user]OctoSquid", "[user]OctoMollusc", "[Group]AddUserToLocalAdminGroup")
        }

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
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