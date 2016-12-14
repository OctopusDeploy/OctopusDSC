# OctopusDSC

This repository contains a PowerShell modeul with DSC resources that can be used to install and configure an [Octopus Deploy](http://octopusdeploy.com) Server and Tentacle agent.

Read about the [cTentacleAgent](README-cTentacleAgent.md) or [cOctopusServer](README-cOctopusServer.md) resources.

Authentication can be configured to use:

* Active Directory Domain with [cOctopusServerActiveDirectoryAuthentication](README-cOctopusServerActiveDirectoryAuthentication.md)
* Azure AD with [cOctopusServerAzureADAuthentication](README-cOctopusServerAzureADAuthentication.md)
* GoogleApps with [cOctopusServerGoogleAppsAuthentication](README-cOctopusServerGoogleAppsAuthentication.md)
* Username/passwords stored in Octopus with [cOctopusServerUsernamePasswordAuthentication](README-cOctopusServerUsernamePasswordAuthentication.md)

## Development

This project is setup to use [Vagrant](vagrant.io) to provide a dev/test environment. Once you've installed Vagrant, you can use [build-virtualbox.sh](build-virtualbox.sh) to spin up a local virtual machine using [VirtualBox](virtualbox.org) and run the test scenarios. On a build server, you most likely want to use [build-aws.sh](build-aws.sh) to spin up a virtual machine on AWS to run the tests.

Configuration is handled by environment variables. The shell scripts will show a message letting you know what variables need to be set.

As there are no windows specific build scripts at present, if you want to run the tests against AWS on windows:

1. Install Vagrant from [vagrantup.com](vagrantup.com)
2. Run `vagrant plugin install vagrant-aws`
3. Run `vagrant plugin install vagrant-aws-winrm`
4. Run `vagrant plugin install vagrant-dsc`
5. Run `vagrant plugin install vagrant-winrm`
6. Run `vagrant plugin install vagrant-winrm-syncedfolders`
7. Set an environment variable `AWS_ACCESS_KEY_ID` to a valid value
8. Set an environment variable `AWS_SECRET_ACCESS_KEY` to a valid value
9. Set an environment variable `AWS_SUBNET_ID` to a valid subnet where you want the instance launched
10. Set an environment variable `AWS_SECURITY_GROUP_ID` to a valid security group you want to assign to the instance
11. Run `vagrant up --provider aws`. This will run all the scenarios under the [Tests](Tests) folder.
12. Run `vagrant destroy -f` once you have finished to kill the virtual machine.

Tests are written in [ServerSpec](serverspec.org), which is an infrastructure oriented layer over [RSpec](rspec.info).

When creating a PR, please ensure that all existing tests run succesfully against VirtualBox, and please include a new scenario where possible.
