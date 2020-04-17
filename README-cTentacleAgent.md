# cTentacleAgent

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort, $Space)

    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Started"

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"

            # Defaults to <MachineName>_<InstanceName> unless overridden
            DisplayName = "My Tentacle"

            # Defaults to 10933 unless otherwise specified
            ListenPort = $ListenPort

            # Required parameters. See full properties list below
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = $Environments
            Roles = $Roles
            Space = $Space # This is for versions 2019.1 and above.  If null or not specified, it uses the space designated as Default
        }
    }
}

SampleConfig -ApiKey "API-ABCDEF12345678910" -OctopusServerUrl "https://demo.octopus.com/" -Environments @("Development") -Roles @("web-server", "app-server") -ListenPort 10933

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Settings

When `Ensure` is set to `Present`, the resource will:

 1. Download the Tentacle MSI from the internet
 2. Install the MSI
 3. Configure Tentacle either in listening mode or polling mode
 4. Add a Windows firewall exception for the listening port (if in listening mode)
 5. Register the Tentacle with your Octopus server, using the registration settings

When `Ensure` is set to `Absent`, the resource will:

 1. De-register the Tentacle from your Octopus server, using the registration settings
 2. Delete the Tentacle windows service
 3. Uninstall using the MSI if there are no other Tentacles installed on this machine

When `State` is `Started`, the resource will ensure that the Tentacle windows service is running. When `Stopped`, it will ensure the service is stopped.

## Properties

| Property                      | Type                                                       | Default Value                                                 | Description |
| ----------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------- | ------------|
| `ApiKey`                      | `string`                                                   |                                                               | The [Api Key](https://octopus.com/docs/api-and-integration/api/how-to-create-an-api-key) to use to register the Tentacle with the Server. |
| `CommunicationMode`           | `string` - `Listen` or `Poll`                              | `Listen`                                                      | The type of Tentacle - whether the Tentacle [listens](https://octopus.com/docs/infrastructure/windows-targets#configure-a-listening-tentacle-recommended) for requests from server, or [actively polls](https://octopus.com/docs/infrastructure/windows-targets#configure-a-polling-tentacle) the server for requests. **Note:** to change the `CommunicationMode`, you need to uninstall and reinstall the Tentacle. |
| `CustomPublicHostName`        | `string`                                                   |                                                               | The `PublicHostName` to use when registering the Tentacle when `PublicHostNameConfiguration` is set to `Custom`. |
| `DefaultApplicationDirectory` | `string`                                                   |                                                               | The default location where to install applications. |
| `DisplayName`                 | `string`                                                   | `<MachineName>_<Name>`                                        | The display name of the Tentacle that is used in the Octopus UI. |
| `Ensure`                      | `string` - `Present` or `Absent`                           | `Present`                                                     | The desired state of the Tentacle - effectively whether to install or uninstall. |
| `Environments`                | `string[]`                                                 |                                                               | An array of [Environments](https://octopus.com/docs/infrastructure/environments) to which to assign the Tentacle. Required if `RegisterWithServer` is `$true`.|
| `ListenPort`                  | `int`                                                      | `10933`                                                       | The port on which the Tentacle should listen, when `CommunicationMode` is set to `Listen`. |
| `TentacleCommsPort`           | `int`                                                      | `ListenPort`                                                  | The comms port that the Octopus server is instructed to call back on to reach this machine; defaults to the configured listening port. Only needs to be specified if the call back port is different from the listen port. e.g the tentacle is behind a loadbalancer. |
| `Name`                        | `string`                                                   |                                                               | The name of the Tentacle instance. Use `Tentacle` by convention unless you have more than one instance. |
| `OctopusServerThumbprint`     | `string`                                                   |                                                               | The certificate thumbprint of the Octopus Server to trust. Useful (combined with `RegisterWithServer` = `$false`) if the Tentacle cannot reach the Server, but the Server can reach the Tentacle. |
| `OctopusServerUrl`            | `string`                                                   |                                                               | The Url of the Octopus server with which to register the Tentacle. |
| `Policy`                      | `string`                                                   |                                                               | The machine policy to assign to the Tentacle. If not set, uses the default machine policy. |
| `PublicHostNameConfiguration` | `string` - `PublicIp`, `FQDN`, `ComputerName` or `Custom`  | `PublicIp`                                                    | The method used to specify the `PublicHostName` of the Tentacle. If `PublicIp`, it uses [api.ipify.org](api.ipify.org) to get the machines public IP address. If `FQDN`, it uses WMI to detemine the DNS host name and the domain. If `ComputerName`, it uses the local computers host name. If `Custom`, it uses the value specified by `CustomPublicHostName`. |
| `RegisterWithServer`          | `boolean`                                                  | `$true`                                                       | Whether to register with the Octopus Server automatically |
| `Roles`                       | `string[]`                                                 |                                                               | An array of [Roles](https://octopus.com/docs/infrastructure/target-roles) to assign to the Tentacle. Required if `RegisterWithServer` is `$true`. |
| `ServerPort`                  | `int`                                                      | `10943`                                                       | The port on which to communicate with the server, when `CommunicationMode` is set to `Poll`. |
| `State`                       | `string` - `Started` or `Stopped`                          | `Started`                                                     | The desired state of the Tentacle service. |
| `Tenants`                     | `string[]`                                                 |                                                               | The Tenants to assign to this Tentacle. Multi-tenancy must be enabled on the Octopus Server. |
| `TenantTags`                  | `string[]`                                                 |                                                               | The TenantTags to assign to this Tentacle, in the format `CustomerType/VIP`. Multi-tenancy must be enabled on the Octopus Server. |
| `TentacleDownloadUrl64`       | `string`                                                   | `https://octopus.com/downloads/latest/OctopusTentacle64`      | The url to use to download the Tentacle, when run on an `x64` architecture. |
| `TentacleDownloadUrl`         | `string`                                                   | `https://octopus.com/downloads/latest/OctopusTentacle`        | The url to use to download the Tentacle, when run on an `x86` architecture. |
| `TentacleHomeDirectory`       | `string`                                                   | `$($env:SystemDrive)\Octopus`                                 | The location where Octopus should store its working files, logs, packages etc. |
| `TentacleServiceCredential`   | `PSCredential`                                             |                                                               | Credentials of the account used to run the Tentacle Service
| `WorkerPools`                 | `string[]`                                                 |                                                               | Worker Pool Name(s) in which this tentacle participates as a worker.
| `TenantedDeploymentParticipation` | `string` - `Untenanted` ,`TenantedOrUntenanted` or `Tenanted`    | `Untenanted`                                        | Determines the Tenancy mode of this tentacle
|  `Space`                      | `string`                                                   |                                                               | The name of the Space in which the tentacle works with

## Drift

Currently the resource only considers the following properties when testing for drift:
* `Ensure`
* `State`
* `TentacleDownloadUrl`/`TentacleDownloadUrl64`
* `WorkerPools`
* `Environments`
* `Roles`

If the `tentacleDownloadUrl` / `tentacleDownloadUrl64` properties change, it will detect the configuration drift and upgrade/downgrade the Tentacle as appropriate. However, if you leave it as default (ie 'install latest'), it will not upgrade when a new version is released - it only acts on change of the property.

However, if you were to set the `ListenPort` to a new port, the drift detection isn't smart enough to check the old configuration, nor update the registered machine. You'll need to uninstall and reinstall for these other settings to take effect.
