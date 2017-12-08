# cOctopusServer

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Started"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminCredential = $PSCredentialObject

            # optional parameters
            AllowUpgradeCheck = $true
            AllowCollectionOfAnonymousUsageStatistics = $true
            ForceSSL = $false
            ListenPort = 10943
            DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer"

            # for pre 3.5, valid values are "UsernamePassword"
            # for 3.5 and above, only "Ignore" is valid (this is the default value)
            LegacyWebAuthenticationMode = "UsernamePassword"

            HomeDirectory = "C:\Octopus"

            # if not supplied, Octopus will use a free license
            LicenseKey = "base64encodedlicense"
        }
    }
}

SampleConfig

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Settings

When `Ensure` is set to `Present`, the resource will:

 1. Download the Octopus Server MSI from the internet
 2. Install the MSI
 3. Create the database
 4. Set the admin username and password
 5. Configure with a free licence
 6. Start the service

When `Ensure` is set to `Absent`, the resource will:

 1. Delete the Octopus Server windows service
 2. Uninstall using the MSI if there are no other instances installed on this machine

When `State` is `Started`, the resource will ensure that the Octopus Servr windows service is running. When `Stopped`, it will ensure the service is stopped.

## Properties

| Property                                     | Type                                                | Default Value                                                   | Description |
| -------------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------| ------------|
| `Ensure`                                     | `string` - `Present` or `Absent`                    | `Present`                                                       | The desired state of the Octopus Server - effectively whether to install or uninstall. |
| `Name`                                       | `string`                                            |                                                                 | The name of the Octopus Server instance. Use `OctopusServer` by convention unless you have more than one instance. |
| `State`                                      | `string` - `Started` or `Stopped`                   | `Started`                                                       | The desired state of the Octopus Server service. |
| `DownloadUrl`                                | `string`                                            | `https://octopus.com/downloads/latest/WindowsX64/OctopusServer` | The url to use to download the msi. |
| `SqlDbConnectionString`                      | `string`                                            |                                                                 | The connection string to use to connect to the SQL Server database. |
| `WebListenPrefix`                            | `string`                                            |                                                                 | A semi-colon (`;`) delimited list of urls on which the server should listen. eg `https://octopus.example.com:81`. |
| `OctopusAdminCredential`                     | `PSCredential`                                      |                                                                 | The name/password of the administrative user to create on first install. |
| `AllowUpgradeCheck`                          | `boolean`                                           | `$true`                                                         | Whether the server should check for updates periodically. |
| `AllowCollectionOfAnonymousUsageStatistics`  | `boolean`                                           | `$true`                                                         | Allow anonymous reporting of usage statistics. |
| `LegacyWebAuthenticationMode`                | `string` - `UsernamePassword`, `Domain` or `Ignore` | `Ignore`                                                        | For Octopus version older than 3.5, allows you to configure how users login. For 3.5 and above, this must be set to `ignore`.  |
| `ForceSSL`                                   | `boolean`                                           | `$false`                                                        | Whether SSL should be required (HTTP requests get redirected to HTTPS) |
| `ListenPort`                                 | `int`                                               | `10943`                                                         | The port on which the Server should listen for communication from `Polling` Tentacles. |
| `AutoLoginEnabled`                           | `boolean`                                           | `$false`                                                        | If an authentication provider is enabled that supports pass through authentcation (eg Active Directory), allow the user to automatically sign in. Only supported from Octopus 3.5. |
| `OctopusServiceCredential`                   | `PSCredential`                                      |                                                                 | Credentials of the account used to run the Octopus Service |
| `HomeDirectory`                              | `string`                                            | `C:\Octopus`                                                    | Home directory for Octopus logs and config (where supported) |
| `LicenseKey`                                 | `string`                                            |                                                                 | The Base64 (UTF8) encoded license key. If not supplied, uses a free license |

## Drift

Currently the resource does not consider `SqlDbConnectionString` or `OctopusAdminCredential` when testing for drift.

This means that the server will be automatically reconfigured if you change any properties except the ones listed above.

If the DownloadUrl property changes, it will detect the configuration drift and upgrade the Server as appropriate. However, if you leave it as default (ie 'install latest'), it will not upgrade when a new version is released - it only actions on change of the property.

However if you need to change any of the `SqlDbConnectionString`, `OctopusAdminCredential` properties, you will need to uninstall then reinstall the server (by changing `Ensure` to `Absent` and then back to `Present`).
