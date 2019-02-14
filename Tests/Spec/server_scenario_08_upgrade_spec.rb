require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should be_file }
  #todo: maybe we should have a matcher "it {should have_version_newer_than('3.3.24.0')}"
  it { should_not have_version('3.3.24.0') } # we should've upgraded past this
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Octopus\\") }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\OctopusServer-OctopusServer.config') }
end

describe file('C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config') do
  it { should exist }
  it { should be_file }
  its(:content) { should match /\"ConfigurationFilePath\": \"C:\\Octopus\\OctopusServer-OctopusServer.config\"/ }
  its(:content) { should match /\"Name\": \"OctopusServer\"/ }
end

describe service('OctopusDeploy') do
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

#environment
describe octopus_deploy_environment(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "UAT 1") do
  it { should_not exist }
end

#dsc overall status
describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end

