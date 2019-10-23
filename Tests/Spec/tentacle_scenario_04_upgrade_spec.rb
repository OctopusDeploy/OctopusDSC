require 'spec_helper'
require 'json'

config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/Applications') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe') do
  it { should be_file }
  #todo: maybe we should have a matcher "it {should have_version_newer_than('3.3.24.0')}"
  it { should_not have_version('3.3.24.0') } # we should've upgraded past this
end

describe service('OctopusDeploy Tentacle') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10933) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "Tentacle") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_listening_tentacle }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_policy('Default Machine Policy') }
end

=begin
describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Tentacle\\") }
end

# reg entry sticks around for backwards compat
describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config') }
end
=end

describe file('C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config')
config_json = JSON.parse(config_file)
describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config') }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
