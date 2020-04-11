require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/ChezOctopus') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/Artifacts') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/Logs') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/Logs/metrics.txt') do
  it { should be_file }
end

describe file('c:/ChezOctopus/TaskLogs') do
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
describe octopus_deploy_environment(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Production") do
  it { should exist }
end

#space
describe octopus_deploy_space(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], 'Integration Team') do
  it { should exist }
  it { should have_description('Description for the Integration Team Space') }
end

#worker pool
describe octopus_deploy_worker_pool(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Secondary Worker Pool") do
  it { should exist }
end

#dsc overall status
describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
