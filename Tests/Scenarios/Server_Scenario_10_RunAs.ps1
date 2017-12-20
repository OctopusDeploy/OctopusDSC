
Configuration Server_Scenario_10_RunAs
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    $svcpass = ConvertTo-SecureString "HyperS3cretPassw0rd!" -AsPlainText -Force
    $svccred = New-Object System.Management.Automation.PSCredential (($env:computername + "\OctoSquid"), $svcpass)

    $runAsPass = ConvertTo-SecureString "ModeratelyS3cretPassw0rd!" -AsPlainText -Force
    $runAsCred = New-Object System.Management.Automation.PSCredential (($env:computername + "\OctoMollusc"), $runAsPass)

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
        }

        User OctoMollusc
        {
            Ensure = "Present"
            UserName = "OctoMollusc"
            Password = $svccred
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
            AllowCollectionOfAnonymousUsageStatistics = $false

            DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.4.1.3-enh-runas0022-x64.msi"

            OctopusServiceCredential = $svccred

            OctopusRunOnServerCredential = $runAsCred

            DependsOn = "[user]OctoSquid"
        }

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }

        cOctopusServerGuestAuthentication "Enable Guest Login"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }

        cOctopusServerActiveDirectoryAuthentication "Enable Active Directory Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $true
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
        }

        cOctopusServerAzureADAuthentication "Enable Azure AD Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://login.microsoftonline.com/b91ebf6a-84be-4c6f-97f3-32a1d0a11c8a"
            ClientID = "0272262a-b31d-4acf-8891-56e96d302018"
        }

        cOctopusServerOktaAuthentication "Enable Okta Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://dev-258251.oktapreview.com"
            ClientID = "752nx5basdskrsbqansE"
        }

        cOctopusServerGoogleAppsAuthentication "Enable GoogleApps Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            ClientID = "5743519123-1232358520259-3634528"
            HostedDomain = "https://octopus.example.com"
        }
    }
}