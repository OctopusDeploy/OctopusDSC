require 'spec_helper'

#we deliberately dont cleanup the octopus directory, as it contains logs & config
describe file('c:/Octopus') do
  it { should exist }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should exist } # as there is another instance still on the box - we shouldn't have removed the binaries
end

describe service('OctopusDeploy') do
  it { should_not be_installed }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_test_dsc_configuration_return_true }
  it { should have_dsc_configuration_status_of_success }
end

describe port(10943) do
  it { should_not be_listening.with('tcp') }
end

describe port(81) do
  it { should_not be_listening.with('tcp') }
end

#todo: confirm whether these should be deleted
# describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
#   it { should_not exist }
# end

# describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
#   it { should_not exist }
# end
