# OctopusDSC

This repository contains a PowerShell module with DSC resources that can be used to install and configure an [Octopus Deploy](http://octopusdeploy.com) Server and Tentacle agent.

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

This project is setup to use [Vagrant](vagrant.io) to provide a dev/test environment. Once you've installed Vagrant, you can use the build scripts to spin up a local virtual machine and run the test scenarios (**NOTE:** The first time you run `vagrant up` it has to download the `octopusdeploy/dsc-test-server` box and this can take some time depending on your Internet speed, so be patient and go grab a coffee while it downloads).

There are four options provided:

 - [build-aws.ps1](build-aws.ps1) 
 - [build-azure.ps1](build-azure.ps1)
 - [build-hyperv-ps1](build-hyperv-ps1) - windows virtualisation
 - [build-virtualbox.ps1](build-virtualbox.ps1) - cross-platform virtualisation

On a build server, you most likely want to use [build-aws.ps1](build-aws.ps1) to spin up a virtual machine on AWS to run the tests.

Configuration is handled by environment variables. The shell scripts will show a message letting you know what variables need to be set.

To run tests locally, follow these steps

1. Install Vagrant from [vagrantup.com](http://vagrantup.com)
2. Install VirtualBox from [virtualbox.org](http://virtualbox.org) or Hyper-V (`Install-WindowsFeature –Name Hyper-V -IncludeManagementTools -Restart`  )
3. _**If you are on a Mac or Linux**_ you need to install PowerShell, see https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md.
4. If you want to test locally using virtualbox
    - Run `vagrant plugin install vagrant-dsc`
    - Run `vagrant plugin install vagrant-winrm`
    - Run `vagrant plugin install vagrant-winrm-syncedfolders`
    - Run `vagrant up -- provider virtualbox`. This will run all the scenarios under the [Tests](Tests) folder.
5. If you want to test using AWS or Azure
    - Run `vagrant plugin install vagrant-aws`
    - Run `vagrant plugin install vagrant-aws-winrm`
    - Set an environment variable `AWS_ACCESS_KEY_ID` to a valid value
    - Set an environment variable `AWS_SECRET_ACCESS_KEY` to a valid value
    - Set an environment variable `AWS_SUBNET_ID` to a valid subnet where you want the instance launched
    - Set an environment variable `AWS_SECURITY_GROUP_ID` to a valid security group you want to assign to the instance
    - Run `vagrant up --provider aws`. This will run all the scenarios under the [Tests](Tests) folder.
6. Run `vagrant destroy -f` once you have finished to kill the virtual machine.

Tests are written in [ServerSpec](serverspec.org), which is an infrastructure oriented layer over [RSpec](rspec.info).

When creating a PR, please ensure that all existing tests run succesfully against VirtualBox, and please include a new scenario where possible. Before you start, please raise an issue to discuss your plans so we can make sure it fits with the goals of the project.
