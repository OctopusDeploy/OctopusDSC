require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/Octopus/Artifacts') do
  it { should be_directory }
end

describe file('c:/Octopus/Logs') do
  it { should be_directory }
end

describe file('c:/Octopus/TaskLogs') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
 it { should exist }
 it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Octopus\\") }
end

describe file('C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config') do
  it { should exist }
  it { should be_file }
  its(:content) { should match /\"ConfigurationFilePath\": \"C:\\\\Octopus\\\\OctopusServer-ConfigurePreInstalledInstance.config\"/ }
  its(:content) { should match /\"Name\": \"ConfigurePreInstalledInstance\"/ }
end

describe service('OctopusDeploy: ConfigurePreInstalledInstance') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10943) do
  it { should be_listening.with('tcp') }
end

describe port(81) do
  it { should be_listening.with('tcp') }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
