$seqPlainTextApiKey = ConvertTo-SecureString "MyMagicSeqApiKey" -AsPlainText -Force
$seqApiKey = New-Object System.Management.Automation.PSCredential ("ignored", $seqPlainTextApiKey)

Configuration Tentacle_Scenario_01_Install
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles, $ServerThumbprint)

    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

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

        cOctopusSeqLogger "Enable logging to seq"
        {
            InstanceType = "Tentacle"
            Ensure = "Present"
            SeqServer = "http://localhost/seq"
            SeqApiKey = $seqApiKey
            Properties = @{ Application = "Octopus"; Server = "MyServer" }
            DependsOn = "[cTentacleAgent]ListeningTentacle"
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
            # ListenPort = $ListenPort;
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

            # Optional settings
            ListenPort = 10935;
            DefaultApplicationDirectory = "C:\Applications"
            CommunicationMode = "Listen"
            TentacleHomeDirectory = "C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome"

            RegisterWithServer = $false
            OctopusServerThumbprint = $ServerThumbprint
        }

        cTentacleAgent WorkerTentacle
        {
            Ensure = "Present";
            State = "Started";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "WorkerTentacle";

            DisplayName = "My Worker Tentacle"

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = 10937;
            DefaultApplicationDirectory = "C:\Applications"
            PublicHostNameConfiguration = "ComputerName"
            TentacleHomeDirectory = "C:\Octopus\WorkerTentacleHome"

            WorkerPools = @("Default Worker Pool")
        }

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
            DependsOn = "[User]ServiceUser"
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

            TentacleServiceCredential = $svccred
            DependsOn = @("[User]ServiceUser", "[Group]AddUserToLocalAdminGroup")
        }
    }
}
