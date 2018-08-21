# README-cOctopusServerOktaAuthentication

This resource is only supported for Octopus 3.16 and above.

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerOktaAuthentication "Enable Okta authentication"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://dev-258251.oktapreview.com"
            ClientId = "752nx5basdskrsbqansE"
        }
    }
}

SampleConfig

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Properties

**Please note: property names are case sensitive**

| Property            | Type         | Default Value    | Description |
| --------------------| ------------ | -----------------| ------------|
| `InstanceName`      | `string`     |                  | The name of the Octopus Server instance. Use `OctopusServer` by convention unless you have more than one instance. |
| `Enabled`           | `boolean`    | `$false`         | Whether to enable Okta authentication. |
| `Issuer`            | `string`     |                  | The 'Issuer' from the Application settings in the Okta portal. |
| `ClientId`          | `string`     |                  | The 'Audience' from the Application settings in the Okta portal. |
