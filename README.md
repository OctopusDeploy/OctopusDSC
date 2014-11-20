This repository contains a PowerShell module with a DSC resource that can be used to install the [Octopus Deploy](http://octopusdeploy.com) Tentacle agent.

## Sample

First, ensure the OctopusDSC module is on your `$env:PSModulePath`. Then you can create and apply configuration like this.

```
Configuration SampleConfig
{
    param ($MachineName)

    Import-DscResource -Module OctopusDSC

    Node $MachineName
    {
        cTentacleAgent OctopusTentacle 
        { 
            Ensure = "Present"; 
            State = "Started"; 
            
            # Tentacle instance name. Leave it as 'Tentacle' unless you have more 
            # than one instance
            Name = "Tentacle";

            # Registration - all parameters required
            ApiKey = "API-ABCDEF12345678910";
            OctopusServerUrl = "https://demo.octopusdeploy.com/";
            Environments = @("Development");
            Roles = @("web-server", "app-server");
            UseHostName = $true

           	# Optional settings
            ListenPort = 10933;
            DefaultApplicationDirectory = "C:\Applications"
        }
    }
}

SampleConfig -MachineName $env:COMPUTERNAME

Start-DscConfiguration .\SampleConfig -Verbose -wait

Test-DscConfiguration
```

## Settings

When `Ensure` is set to `Present`, the resource will:

 1. Download the Tentacle MSI from the internet
 2. Install the MSI
 3. Configure Tentacle in listening mode on the specified port (10933 by default)
 4. Add a Windows firewall exception for the listening port
 5. Register the Tentacle with your Octopus server, using the registration settings

When `Ensure` is set to `Absent`, the resource will:

 1. De-register the Tentacle from your Octopus server, using the registration settings
 2. Delete the Tentacle windows service
 3. Uninstall using the MSI

When `State` is `Started`, the resource will ensure that the Tentacle windows service is running. When `Stopped`, it will ensure the service is stopped.

## Drift

Currently the resource only considers the `Ensure` and `State` properties when testing for drift. 

This means that if you set `Ensure` to `Present` to install Tentacle, then later set it to `Absent`, testing the configuration will return `$false`. Likewise if you set the `State` to `Stopped` and the service is running. 

However, if you were to set the `ListenPort` to a new port, the drift detection isn't smart enough to check the old configuration, nor update the registered machine. You'll need to uninstall and reinstall for these other settings to take effect.

## Development
If you are making changes to the module, keep in mind that your changes may not be loaded, as the module gets cached by `WmiPrvSE`. You can use the following command to kill `WmiPrvSE`:

```
Stop-Process -Name WmiPrvSE -Force -ErrorAction SilentlyContinue | out-null
```

