# cOctopusServer

## Important note about usage statistics

We had previously made an inadvertent representation with regard to the collection of usage statistics. We had called the parameter `AllowCollectionOfAnonymousUsageStatistics`, when in fact it is possible for us to link this usage to your license key.

If this is enabled, we only collect aggregated feature usage statistics, such as number of projects, number of environments, number of machines etc. We never collect detailed information - things like names, descriptions, urls, variables etc are never collected. Please see [our docs](https://octopus.com/docs/administration/security/outbound-requests#Outboundrequests-WhatinformationisincludedwhenOctopuschecksforupdates) for full details on whats included.

As this was a change we wanted to bring to your attention, we have bumped the major version number (to represent a breaking change) and renamed the parameter to allow you the chance to change the setting.

If you wish to have your usage data deleted, please send us an email to <support@octopus.com> with the serial number from your license key and we will delete it from our database.

We sincerely apologise for the mistake.

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
            AllowCollectionOfUsageStatistics = $true
            ForceSSL = $false
            ListenPort = 10943
            DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer"
            HSTSEnabled = $false
            HSTSMaxAge = 3600 # 1hour

            # for pre 3.5, valid values are "UsernamePassword"
            # for 3.5 and above, only "Ignore" is valid (this is the default value)
            LegacyWebAuthenticationMode = "UsernamePassword"

            HomeDirectory = "C:\Octopus"
            TaskLogsDirectory = "E:\OctopusTaskLogs" # defaults to "$HomeDirectory\TaskLogs"
            PackagesDirectory = "E:\OctopusPackages" # defaults to "$HomeDirectory\Packages"
            ArtifactsDirectory = "E:\OctopusArtifacts" # defaults to "$HomeDirectory\Artifacts"

            # if not supplied, Octopus will use a free license
            LicenseKey = "base64encodedlicense"

            # whether to log metrics
            LogTaskMetrics = $false
            LogRequestMetrics = $false

            TaskCap = 10
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

| Property                              | Type                                                | Default Value                                                   | Description |
| ------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------| ------------|
| `Ensure`                              | `string` - `Present` or `Absent`                    | `Present`                                                       | The desired state of the Octopus Server - effectively whether to install or uninstall. |
| `Name`                                | `string`                                            |                                                                 | The name of the Octopus Server instance. Use `OctopusServer` by convention unless you have more than one instance. |
| `State`                               | `string` - `Started` or `Stopped`                   | `Started`                                                       | The desired state of the Octopus Server service. |
| `DownloadUrl`                         | `string`                                            | `https://octopus.com/downloads/latest/WindowsX64/OctopusServer` | The url to use to download the msi. |
| `SqlDbConnectionString`               | `string`                                            |                                                                 | The connection string to use to connect to the SQL Server database. |
| `WebListenPrefix`                     | `string`                                            |                                                                 | A semi-colon (`;`) delimited list of urls on which the server should listen. eg `https://octopus.example.com:81`. |
| `OctopusAdminCredential`              | `PSCredential`                                      | `[PSCredential]::Empty`                                         | The name/password of the administrative user to create on first install. |
| `AllowUpgradeCheck`                   | `boolean`                                           | `$true`                                                         | Whether the server should check for updates periodically. |
| `AllowCollectionOfUsageStatistics`    | `boolean`                                           | `$true`                                                         | Allow reporting of aggregated feature usage statistics during upgrade check, such as number of Tentacles/projects/environments etc. |
| `LegacyWebAuthenticationMode`         | `string` - `UsernamePassword`, `Domain` or `Ignore` | `Ignore`                                                        | For Octopus version older than 3.5, allows you to configure how users login. For 3.5 and above, this must be set to `ignore`.  |
| `ForceSSL`                            | `boolean`                                           | `$false`                                                        | Whether SSL should be required (HTTP requests get redirected to HTTPS) |
| `ListenPort`                          | `int`                                               | `10943`                                                         | The port on which the Server should listen for communication from `Polling` Tentacles. |
| `HSTSEnabled`                         | `boolean`                                           | `$false`                                                        | Whether Octopus should send the HSTS header |
| `HSTSMaxAge`                          | `int`                                               | `3600`                                                          | The max age of the HSTS header |
| `AutoLoginEnabled`                    | `boolean`                                           |                                                                 | If an authentication provider is enabled that supports pass through authentication (eg Active Directory), allow the user to automatically sign in. Only supported from Octopus 3.5. |
| `OctopusServiceCredential`            | `PSCredential`                                      | `[PSCredential]::Empty`                                         | Credentials of the account used to run the Octopus Service |
| `HomeDirectory`                       | `string`                                            | `C:\Octopus`                                                    | Home directory for Octopus logs and config (where supported) |
| `PackagesDirectory`                   | `string`                                            | `$HomeDirectory\Packages`                                       | Directory where uploaded packages are stored. |
| `ArtifactsDirectory`                  | `string`                                            | `$HomeDirectory\Artifacts`                                      | Directory where deployment artifacts are stored |
| `TaskLogsDirectory`                   | `string`                                            | `$HomeDirectory\TaskLogs`                                       | Directory where deployment logs are stored |
| `LicenseKey`                          | `string`                                            |                                                                 | The Base64 (UTF8) encoded license key. If not supplied, uses a free license. Drift detection is only supported from Octopus 4.1.3. |
| `SkipLicenseCheck`                    | `boolen`                                            | `$false`                                                        | Force the license to be applied by skipping the license compliance check. Warning: if your installation is not compliant with your license, deployments and other activities may be blocked. |
| `GrantDatabasePermissions`            | `boolean`                                           | `$true`                                                         | Whether to grant `db_owner` permissions to the service account user (`$OctopusServiceCredential` user if supplied, or `NT AUTHORITY\System`)  |
| `OctopusMasterKey`                    | `PSCredential`                                      | `[PSCredential]::Empty`                                         | The master key for the existing database. |
| `OctopusBuiltInWorkerCredential`      | `PSCredential`                                      | `[PSCredential]::Empty`                                         | The user account to use to execute run-on-server scripts. If not supplied, executes scripts under the service account used for `Octopus.Server.exe` |
| `LogTaskMetrics`                      | `boolean`                                           | `$false`                                                        | Whether to log task metrics |
| `LogRequestMetrics`                   | `boolean`                                           | `$false`                                                        | Whether to log api requests metrics |
| `TaskCap`                             | `int`                                               |                                                                 | The number of tasks this Octopus Server node should attempt to process at once |

## Drift

The server will be automatically reconfigured if you change any properties above. If the `DownloadUrl` property changes, it will detect the configuration drift and upgrade the Server as appropriate. However, if you leave it as default (ie 'install latest'), it will not upgrade when a new version is released - it only actions on change of the property.
