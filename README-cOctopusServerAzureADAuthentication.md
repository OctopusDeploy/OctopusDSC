# README-cOctopusServerAzureADAuthentication

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerAzureADAuthentication "Enable AzureAD authentication"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://login.microsoftonline.com/b91ebf6a-84be-4c6f-97f3-32a1d0a11c8a"
            ClientId = "0272262a-b31d-4acf-8891-56e96d302018"
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
| `Enabled`           | `boolean`    | `$false`         | Whether to enable AzureAD authentication. |
| `Issuer`            | `string`     |                  | The `OAuth 2.0 Authorization Endpoint` from the Azure Portal, with the trailing `/oauth2/authorize` removed. |
| `ClientId`          | `string`     |                  | The `Application ID` from the Azure Portal. |
