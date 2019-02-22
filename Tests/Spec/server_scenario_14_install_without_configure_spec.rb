require 'spec_helper'

# from previous install
describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Octopus\\") }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
  it { should_not exist }
end

describe file('C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config') do
  it { should_not exist }
end

describe service('OctopusDeploy') do
  it { should_not be_installed }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
