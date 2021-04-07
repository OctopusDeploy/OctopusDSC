# README-cOctopusServerSslCertificate

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerSslCertificate SSLCert
        {
            InstanceName = "OctopusServer"
            Thumbprint = "c42a148bcd3959101f2e7a3d76edb924bff84b6b"
            Ensure = "Present"
            StoreName = "My"
            Port = 443
        }
    }
}

SampleConfig

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Properties
| Property                                  | Type         | Default Value    | Description |
| ------------------------------------------| ------------ | -----------------| ------------|
| `Ensure`                              | `string` - `Present` or `Absent`                    | `Present`                                                       | The desired state of the Octopus Server - effectively whether to install or uninstall. |
| `InstanceName`                            | `string`     |                  | The name of the Octopus Server instance. Use `OctopusServer` by convention unless you have more than one instance. |
| `Thumbprint`                                 | `string`    |          | Thumbprint of the SSL certificate to use with Octopus Deploy |
| `StoreName`  | `string` - `My` or `WebHosting`    |          | Which certificate store to look for the thumbprint in. |
| `Port`                | `int`     |                  | The port to use SSL on.  |
