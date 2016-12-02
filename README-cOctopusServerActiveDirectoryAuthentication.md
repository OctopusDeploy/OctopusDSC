# README-cOctopusServerActiveDirectoryAuthentication

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerActiveDirectoryAuthentication "Enable AD authentication"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $false
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
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
| `InstanceName`                            | `string`     |                  | The name of the Octopus Server instance. Use `OctopusServer` by convention unless you have more than one instance. |
| `Enabled`                                 | `boolean`    | `$false`         | Whether to enable Active Directory authentication. |
| `AllowFormsAuthenticationForDomainUsers`  | `boolean`    | `$false`         | Whether to allow users to manually enter a username and password. |
| `ActiveDirectoryContainer`                | `string`     |                  | The active directory container (if user objects are stored in a non-standard location).  |
