require 'spec_helper'

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

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "ListeningTentacle") do
  it { should_not exist }
end

describe port(10933) do
  it { should_not be_listening.with('tcp') }
end

describe service('OctopusDeploy Tentacle: PollingTentacle') do
  it { should_not be_installed }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "PollingTentacle") do
  it { should_not exist }
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
