# cTentacleAgent

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort)

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

            # Registration - all parameters required
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = $Environments
            Roles = $Roles

            # Optional settings
            ListenPort = $ListenPort
            DefaultApplicationDirectory = "C:\Applications"
        }
    }
}

SampleConfig -ApiKey "API-ABCDEF12345678910" -OctopusServerUrl "https://demo.octopusdeploy.com/" -Environments @("Development") -Roles @("web-server", "app-server") -ListenPort 10933

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
| `Ensure`                      | `string` - `Present` or `Absent`                           | `Present`                                                     | The desired state of the Tentacle - effectively whether to install or uninstall. |
| `Name`                        | `string`                                                   |                                                               | The name of the Tentacle instance. Use `Tentacle` by convention unless you have more than one instance. |
| `DisplayName`                 | `string`                                                   | `<Name>_<MachineName>`                                        | The display name of the Tentacle that is used in the Octopus UI. |
| `State`                       | `string` - `Started` or `Stopped`                          | `Started`                                                     | The desired state of the Tentacle service. |
| `CommunicationMode`           | `string` - `Listen` or `Poll`                              | `Listen`                                                      | The type of Tentacle - whether the Tentacle [listens](http://docs.octopusdeploy.com/display/OD/Listening+Tentacles) for requests from server, or [actively polls](http://docs.octopusdeploy.com/display/OD/Polling+Tentacles) the server for requests. **Note:** to change the `CommunicationMode`, you need to uninstall and reinstall the Tentacle. |
| `ApiKey`                      | `string`                                                   |                                                               | The [Api Key](http://docs.octopusdeploy.com/display/OD/How+to+create+an+API+key) to use to register the Tentacle with the Server. |
| `OctopusServerUrl`            | `string`                                                   |                                                               | The Url of the Octopus server with which to register the Tentacle. |
| `Environments`                | `string[]`                                                 |                                                               | An array of [Environments](http://docs.octopusdeploy.com/display/OD/Environments) to which to assign the Tentacle. |
| `Roles`                       | `string[]`                                                 |                                                               | An array of [Roles](http://docs.octopusdeploy.com/display/OD/Machine+Roles) to assign to the Tentacle. |
| `DefaultApplicationDirectory` | `string`                                                   |                                                               | The default location where to install applications. |
| `ListenPort`                  | `int`                                                      | `10933`                                                       | The port on which the Tentacle should listen, when `CommunicationMode` is set to `Listen`. |
| `ServerPort`                  | `int`                                                      | `10943`                                                       | The port on which to communicate with the server, when `CommunicationMode` is set to `Poll`. |
| `tentacleDownloadUrl`         | `string`                                                   | `http://octopusdeploy.com/downloads/latest/OctopusTentacle`   | The url to use to download the Tentacle, when run on an `x86` architecture. |
| `tentacleDownloadUrl64`       | `string`                                                   | `http://octopusdeploy.com/downloads/latest/OctopusTentacle64` | The url to use to download the Tentacle, when run on an `x64` architecture. |
| `PublicHostNameConfiguration` | `string` - `PublicIp`, `FQDN`, `ComputerName` or `Custom`  | `PublicIp`                                                    | The method used to specify the `PublicHostName` of the Tentacle. If `PublicIp`, it uses [api.ipify.org](api.ipify.org) to get the machines public IP address. If `FQDN`, it uses WMI to detemine the DNS host name and the domain. If `ComputerName`, it uses the local computers host name. If `Custom`, it uses the value specified by `CustomPublicHostName`. |
| `CustomPublicHostName`        | `string`                                                   |                                                               | The `PublicHostName` to use when registering the Tentacle when `PublicHostNameConfiguration` is set to `Custom`. |


## Drift

Currently the resource only considers the `Ensure`, `State` and `TentacleDownloadUrl`/`TentacleDownloadUrl64` properties when testing for drift.

This means that if you set `Ensure` to `Present` to install Tentacle, then later set it to `Absent`, testing the configuration will return `$false`. Likewise if you set the `State` to `Stopped` and the service is running.

If the tentacleDownloadUrl / tentacleDownloadUrl64 properties change, it will detect the configuration drift and upgrade/downgrade the Tentacle as appropriate. However, if you leave it as default (ie 'install latest'), it will not upgrade when a new version is released - it only actions on change of the property.

However, if you were to set the `ListenPort` to a new port, the drift detection isn't smart enough to check the old configuration, nor update the registered machine. You'll need to uninstall and reinstall for these other settings to take effect.
