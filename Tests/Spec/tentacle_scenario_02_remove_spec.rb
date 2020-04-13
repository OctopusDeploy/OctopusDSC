require 'spec_helper'
require 'json'

config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

#we deliberately dont cleanup the octopus directory, as it contains logs & config
describe file('c:/Octopus') do
  it { should exist }
end

describe file('c:/Applications') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe') do
  it { should_not exist }
end

describe service('OctopusDeploy Tentacle: ListeningTentacle') do
  it { should_not be_installed }
end

# Listening Tentacle
describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "ListeningTentacle") do
  it { should_not exist }
end

describe port(10933) do
  it { should_not be_listening.with('tcp') }
end

# Polling Tentacle
describe service('OctopusDeploy Tentacle: PollingTentacle') do
  it { should_not be_installed }
end

describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacle") do
  it { should_not exist }
end

# Polling Tentacle
describe service('OctopusDeploy Tentacle: PollingTentacle') do
  it { should_not be_installed }
end

describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacle") do
  it { should_not exist }
end

# Polling Tentacle with autoregister disabled
describe service('OctopusDeploy Tentacle: PollingTentacleWithoutAutoRegister') do
  it { should_not be_installed }
end

describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacleWithoutAutoRegister") do
  it { should_not exist }
end

# Polling Tentacle with autoregister disabled but thumbprint set
describe service('OctopusDeploy Tentacle: PollingTentacleWithThumbprintWithoutAutoRegister') do
  it { should_not be_installed }
end

describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacleWithThumbprintWithoutAutoRegister") do
  it { should_not exist }
end

# Worker Tentacle
describe service('OctopusDeploy Tentacle: WorkerTentacle') do
  it { should_not be_installed }
end

describe octopus_deploy_worker(config['OctopusServerUrl'], config['OctopusApiKey'], "WorkerTentacle") do
  it { should_not exist }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_test_dsc_configuration_return_true }
  it { should have_dsc_configuration_status_of_success }
end

#todo: confirm whether these should be deleted
#describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle') do
#  it { should_not exist }
#end
#
#describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle') do
#  it { should_not exist }
#end


#todo: can we check its been removed from the server somehow?
