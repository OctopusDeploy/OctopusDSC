# OctopusDSC

This repository contains a PowerShell module with DSC resources that can be used to install and configure an [Octopus Deploy](http://octopus.com) Server and Tentacle agent.

There are two main resources:

* [cOctopusServer](README-cOctopusServer.md) to install and configure an Octopus Server, and
* [cTentacleAgent](README-cTentacleAgent.md) to install and configure a Tentacle.

Server authentication can be configured to use:

* Active Directory with [cOctopusServerActiveDirectoryAuthentication](README-cOctopusServerActiveDirectoryAuthentication.md)
* Azure AD with [cOctopusServerAzureADAuthentication](README-cOctopusServerAzureADAuthentication.md)
* GoogleApps with [cOctopusServerGoogleAppsAuthentication](README-cOctopusServerGoogleAppsAuthentication.md)
* Okta with [cOctopusServerOktaAuthentication](README-cOctopusServerOktaAuthentication.md)
* Username/passwords stored in Octopus with [cOctopusServerUsernamePasswordAuthentication](README-cOctopusServerUsernamePasswordAuthentication.md)
* Read-only guest account login with [cOctopusServerGuestAuthentication](README-cOctopusServerGuestAuthentication.md)

Other resources of note are:
* [cOctopusServerSpace](README-cOctopusServerSpace.md) to manage spaces
* [cOctopusServerSslCertificate](README-OctopusServerSslCertificate) to configure the server to use Ssl with a certificate

Version 3.0 of OctopusDSC supports Octopus Deploy 4.x and above with backwards compatibility to 3.x

## Installation

### [PowerShellGet](https://technet.microsoft.com/en-us/library/dn807169.aspx) / PowerShell 5 (recommended)
1. Install PowerShellGet from [PowerShell Gallery](https://www.powershellgallery.com/GettingStarted)
2. Install DSC module via `PowerShellGet\Install-Module -Name OctopusDSC`

### Manual ###
1. Download the [latest release](https://github.com/OctopusDeploy/OctopusDSC/releases)
2. If required, unblock the zip file
3. Extract the zip file to a folder called OctopusDSC under your modules folder (usually `%USERPROFILE%\Documents\WindowsPowerShell\Modules`)
4. To confirm it's installed correctly, in a new powershell session run `Get-Module -ListAvailable -Name OctopusDSC`

The community has also submitted a few [other options](https://github.com/OctopusDeploy/OctopusDSC/issues/14).

## Development

This project is setup to use [Vagrant](vagrant.io) to provide a dev/test environment. Once you've installed Vagrant, you can use the build scripts to spin up a local virtual machine and run the test scenarios 

There are four options provided:

 - [build-aws.ps1](build-aws.ps1)
 - [build-azure.ps1](build-azure.ps1)

On a build server, you most likely want to use [build-aws.ps1](build-aws.ps1) to spin up a virtual machine on AWS to run the tests.

Configuration is handled by environment variables. The shell scripts will show a message letting you know what variables need to be set. `The build-*` scripts also invoke [Pester](https://github.com/Pester/Pester) and [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) tests, so you'll need those modules installed.  Be sure to update [Pester](https://github.com/Pester/Pester), the version that ships with Windows 10 is incompatible.

To run just the scenarios locally, follow these steps:

1. Install Vagrant from [vagrantup.com](https://vagrantup.com). (Note: version after 2.2.3 have altered WinRM upload behaviour which may cause issues)
2. _**If you are on a Mac or Linux**_ you need to install PowerShell, see https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md.
3. If you want to test using AWS
    - Run `vagrant plugin install vagrant-aws`. If you run into issues around libxml2, take a look at https://github.com/mitchellh/vagrant-aws/issues/539
    - Run `vagrant plugin install vagrant-aws-winrm`
    - Set an environment variable `AWS_ACCESS_KEY_ID` to a valid value
    - Set an environment variable `AWS_SECRET_ACCESS_KEY` to a valid value
    - Set an environment variable `AWS_SUBNET_ID` to a valid subnet where you want the instance launched
    - Set an environment variable `AWS_SECURITY_GROUP_ID` to a valid security group you want to assign to the instance
    - Run `build-aws.ps1`. This will run all the scenarios under the [Tests](Tests) folder.
4. If you want to test using Azure
    - Run `vagrant plugin install vagrant-azure`
    - Set an environment variable `AZURE_VM_PASSWORD` to a valid value
    - Set an environment variable `AZURE_SUBSCRIPTION_ID` to a valid value
    - Set an environment variable `AZURE_TENANT_ID` to a valid value
    - Set an environment variable `AZURE_CLIENT_ID` to a valid value
    - Srt an environment variable `AZURE_CLIENT_SECRET` to a valid value
    - Run `build-azure.ps1`. This will run all the scenarios under the [Tests](Tests) folder.
5. Run `vagrant destroy -f` or the appropriate `cleanup-*.ps1` once you have finished to kill the virtual machine.

Each of the `build-*` scripts can take parameters at the command prompt.

These are generally designed to tighten the feedback loop during development, since the VM-based integration test phase can be quite time consuming.

| Parameter                     | Type      | Default Value    | Description |
| ----------------------------- | --------- | ---------------- | -------------------------------------------- |
| `-SkipPester`                 | Switch    | False            | Skips the Pester and PSScriptAnalyzer unit tests, going straight to the slower, VM-based integration tests.            |
| `-ServerOnly`                 | Switch    | False            | Runs only the Server-related integration scenarios. |
| `-TentacleOnly`               | Switch    | False            | Runs Server scenarios 14 and 15 to install and configure an Octopus Deploy server instance, then moves on to Tentacle-related tests (which require a server to be present). |
| `-OctopusVersion`             | String    | `vLatest`        | Allows you to run tests against a specific version of Octopus Deploy. Does not apply to 'Scenario_07', which installs an older version in order to test upgrading. |
| `-RetainOnDestroy`            | Switch    | False            | Retains the virtual machine after the tests finish, so you can examine the state of the VM. |
| `-debug`                      | Switch    | False            | Adds the `--debug` flag to the vagrant invocation, allowing you to step through the process and examine machine state before moving on. |

Tests are written in [ServerSpec](serverspec.org), which is an infrastructure oriented layer over [RSpec](rspec.info) and use our [octopus-serverspec-extensions](https://github.com/OctopusDeploy/octopus-serverspec-extensions) project for octopus-specific tests.

When creating a PR, please ensure that all existing tests run succesfully, and please include a new scenario where possible. Before you start, please raise an issue to discuss your plans so we can make sure it fits with the goals of the project.
