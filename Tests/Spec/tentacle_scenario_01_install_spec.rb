require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/Applications') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Tentacle\\") }
end


### listening tentacle:

describe service('OctopusDeploy Tentacle: ListeningTentacle') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10933) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "ListeningTentacle") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name('My Listening Tentacle')}
  it { should have_tenant('John') }
  it { should have_tenant_tag('Hosting', 'Cloud') }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\ListeningTentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\ListeningTentacleHome\ListeningTentacle\Tentacle.config') }
end

### polling tentacle:

describe service('OctopusDeploy Tentacle: PollingTentacle') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "PollingTentacle") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name("#{ENV['COMPUTERNAME']}_PollingTentacle")}
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\PollingTentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\PollingTentacleHome\PollingTentacle\Tentacle.config') }
end

describe command('$ProgressPreference = "SilentlyContinue"; try { Get-DSCConfiguration -ErrorAction Stop; write-output "Get-DSCConfiguration succeeded"; $true } catch { write-output "Get-DSCConfiguration failed"; write-output $_; $false }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Get-DSCConfiguration succeeded/ }
end

describe command('$ProgressPreference = "SilentlyContinue"; try { if (-not (Test-DSCConfiguration -ErrorAction Stop)) { write-output "Test-DSCConfiguration returned false"; exit 1 } write-output "Test-DSCConfiguration succeeded"; exit 0 } catch { write-output "Test-DSCConfiguration failed"; write-output $_; exit 2 }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Test-DSCConfiguration succeeded/ }
end
