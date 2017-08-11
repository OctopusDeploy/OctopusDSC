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

## Development

This project is setup to use [Vagrant](vagrant.io) to provide a dev/test environment. Once you've installed Vagrant, you can use [build-virtualbox.sh](build-virtualbox.sh) to spin up a local virtual machine using [VirtualBox](virtualbox.org) and run the test scenarios (**NOTE:** The first time you run `vagrant up` it has to download the `octopusdeploy/dsc-test-server` box and this can take some time depending on your Internet speed, so be patient and go grab a coffee while it downloads). On a build server, you most likely want to use [build-aws.sh](build-aws.sh) to spin up a virtual machine on AWS to run the tests.

Configuration is handled by environment variables. The shell scripts will show a message letting you know what variables need to be set.

As there are no windows specific build scripts at present, if you want to run the tests against AWS on windows:

1. Install Vagrant from [vagrantup.com](http://vagrantup.com)
2. Install VirtualBox from [virtualbox.org](http://virtualbox.org)
3. _**If you are on a Mac or Linux**_ you need to install PowerShell, see https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md.
4. If you want to test locally using virtualbox
    - Run `vagrant plugin install vagrant-dsc`
    - Run `vagrant plugin install vagrant-winrm`
    - Run `vagrant plugin install vagrant-winrm-syncedfolders`
    - Run `vagrant up -- provider virtualbox`. This will run all the scenarios under the [Tests](Tests) folder.
5. If you want to test using AWS
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
