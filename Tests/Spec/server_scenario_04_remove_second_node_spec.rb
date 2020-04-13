require 'spec_helper'

#we deliberately dont cleanup the octopus directory, as it contains logs & config
describe file('c:/Octopus') do
  it { should exist }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should_not exist }
end

describe service('OctopusDeploy: HANode') do
  it { should_not be_installed }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_test_dsc_configuration_return_true }
  it { should have_dsc_configuration_status_of_success }
end

#todo: add a new type/matcher to the `octopus-serverspec-extensions` project
#the port can still be in a TIME_WAIT state for upto 4 minutes and these tests can fail because of that
#describe port(10943) do
#  it { should_not be_listening.with('tcp') }
#end

#describe port(81) do
#  it { should_not be_listening.with('tcp') }
#end

#todo: confirm whether these should be deleted
# describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
#   it { should_not exist }
# end

# describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
#   it { should_not exist }
# end
