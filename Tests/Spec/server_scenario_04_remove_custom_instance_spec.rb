require 'spec_helper'

#we deliberately dont cleanup the octopus directory, as it contains logs & config
describe file('c:/Octopus') do
  it { should exist }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should_not exist }
end

describe service('OctopusDeploy: MyOctopusServer') do
  it { should_not be_installed }
end

describe command('$ProgressPreference = "SilentlyContinue"; try { Get-DSCConfiguration -ErrorAction Stop; write-output "Get-DSCConfiguration succeeded"; $true } catch { write-output "Get-DSCConfiguration failed"; write-output $_; $false }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Get-DSCConfiguration succeeded/ }
end

describe command('$ProgressPreference = "SilentlyContinue"; try { if (-not (Test-DSCConfiguration -ErrorAction Stop)) { write-output "Test-DSCConfiguration returned false"; exit 1 } write-output "Test-DSCConfiguration succeeded"; exit 0 } catch { write-output "Test-DSCConfiguration failed"; write-output $_; exit 2 }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Test-DSCConfiguration succeeded/ }
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
