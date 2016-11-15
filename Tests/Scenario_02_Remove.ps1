Configuration Scenario_02_Remove
{
    param ($OctopusServerUrl, $ApiKey, $Environments, $Roles, $ListenPort)

    Import-DscResource -ModuleName OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Absent";
            State = "Stopped";

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle";

            # Registration - all parameters required
            ApiKey = $ApiKey;
            OctopusServerUrl = $OctopusServerUrl;
            Environments = $Environments;
            Roles = $Roles;

            # Optional settings
            ListenPort = $ListenPort;
            DefaultApplicationDirectory = "C:\Applications"
        }
    }
}
