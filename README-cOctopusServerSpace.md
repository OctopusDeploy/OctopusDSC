# README-cOctopusServerSpace

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```PowerShell
Configuration SampleConfig
{
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cOctopusServerSpace "Ensure Integration Team Space exists"
        {
            Ensure = "Present"
            Name = "Integration Team"
            Description = "The top secret work of the Integration Team"
            Url = "https://octopus.example.com"
            SpaceManagersTeamMembers = [ "bob.smith" ]
            SpaceManagersTeams = [ "Release Managers", "Integration Team Managers" ]
            OctopusApiKey = $creds
        }
    }
}

SampleConfig

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Properties

| Property                    | Type                               | Default Value    | Description                                                                                                                  |
| --------------------------- | ---------------------------------- | -----------------| ---------------------------------------------------------------------------------------------------------------------------- |
| `Ensure`                    | `string` - `Present` or `Absent`   | `Present`        | The desired state of the Space - effectively whether to create or delete.                                                    |
| `Name`                      | `string`                           |                  | The name of the space                                                                                                        |
| `Description`               | `string`                           |                  | Description to use for the space                                                                                             |
| `SpaceManagersTeamMembers`  | `string`                           |                  | Usernames for users will get Space Manager rights to the space                                                               |
| `SpaceManagersTeams`        | `string`                           |                  | Teams that will get Space Manager rights to the space                                                                        |
| `Url`                       | `string`                           |                  | Description to use for the space                                                                                             |
| `OctopusApiKey`             | `PSCredential`                     |                  | A `PSCredential` object with an empty username & password set to the api key to use to authenticate with your Octopus Server |
| `OctopusCredentials`        | `PSCredential`                     |                  | A `PSCredential` object with the username & password to use to authenticate with your Octopus Server                         |
