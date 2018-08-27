# README-cOctopusServerGuestAuthentication

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerGuestAuthentication "Enable guest account login"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }
    }
}

SampleConfig

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Properties

| Property            | Type         | Default Value    | Description |
| --------------------| ------------ | -----------------| ------------|
| `InstanceName`      | `string`     |                  | The name of the Octopus Server instance. Use `OctopusServer` by convention unless you have more than one instance. |
| `Enabled`           | `boolean`    | `$false`         | Whether to enable the read-only guest account. |
