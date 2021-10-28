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

describe file('C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config') do
  it { should exist }
  it { should be_file }
  its(:content) { should match /\"ConfigurationFilePath\": \"C:\\\\Octopus\\\\OctopusServer-OctopusServer.config\"/ }
  its(:content) { should match /\"Name\": \"OctopusServer\"/ }
end

describe user('OctoSquid') do
  it { should exist }
  it { should belong_to_group('Administrators')}
end

describe user('OctoMollusc') do
  it { should exist }
  it { should_not belong_to_group('Administrators')}
end

describe service('OctopusDeploy') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('.\OctoSquid') }
end

describe command('& "C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" show-configuration --instance OctopusServer --format xml') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /<set key="Octopus.BuiltInWorker.CustomAccountUserName">OctoMollusc<\/set>/ }
end

describe port(10943) do
  it { should be_listening.with('tcp') }
end

describe port(81) do
  it { should be_listening.with('tcp') }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_test_dsc_configuration_return_true }
  it { should have_dsc_configuration_status_of_success }
end
