Configuration Tentacle_Scenario_01_Install
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles, $ServerThumbprint)

    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cTentacleAgent ListeningTentacle
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacle";

            DisplayName = "My Listening Tentacle"

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = 10933;
            DefaultApplicationDirectory = "C:\Applications"
            PublicHostNameConfiguration = "ComputerName"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleHome"

            Tenants = "John"
            TenantTags = "Hosting/Cloud"

            Policy = "Test Policy"
        }

        cTentacleAgent PollingTentacle
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "PollingTentacle";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = $ListenPort;
            DefaultApplicationDirectory = "C:\Octopus\Applications Directory"
            CommunicationMode = "Poll"
            TentacleHomeDirectory = "C:\Octopus\Polling Tentacle Home"
        }

        cTentacleAgent ListeningTentacleWithoutAutoRegister
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacleWithoutAutoRegister";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;

            # Optional settings
            ListenPort = 10934;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Listen"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithoutAutoRegisterHome"

            RegisterWithServer = $false
        }

        cTentacleAgent ListeningTentacleWithThumbprintWithoutAutoRegister
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacleWithThumbprintWithoutAutoRegister";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;

            # Optional settings
            ListenPort = 10935;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Listen"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome"

            RegisterWithServer = $false
            OctopusServerThumbprint = $ServerThumbprint
        }

        # create a custom user. 2012 requires some ADSI
        # Create new local Admin user for script purposes

        # load the credential for said user
        $svcpass = ConvertTo-SecureString "HyperS3cretPassw0rd!" -AsPlainText -Force
        $svccred = New-Object System.Management.Automation.PSCredential (($env:computername + "\ServiceUser"), $svcpass)

        User ServiceUser
        {
            Ensure = "Present"
            UserName = "ServiceUser"
            Password = $svccred
            PasswordChangeRequired = $false
        }

        Group AddUserToLocalAdminGroup
        {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= ".\ServiceUser"
        }

        cTentacleAgent ListeningTentacleWithCustomAccount
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "ListeningTentacleWithCustomAccount";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = 10936;
            DefaultApplicationDirectory = "C:\Applications"
            PublicHostNameConfiguration = "ComputerName"
            DisplayName = "ListeningTentacleWithCustomAccount"
            CommunicationMode = "Listen"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithCustomAccountHome"

            TentacleServiceCredential = $serviceusercredential
            DependsOn = "[user]ServiceUser"
        }
    }
}
