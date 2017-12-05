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
  it { should be_listening_tentacle }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name('My Listening Tentacle') }
  it { should have_tenant('John') }
  it { should have_tenant_tag('Hosting', 'Cloud') }
  it { should have_policy('Test Policy') }
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
  it { should be_polling_tentacle }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name("#{ENV['COMPUTERNAME']}_PollingTentacle") }
  it { should have_policy('Default Machine Policy') }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\PollingTentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\Polling Tentacle Home\PollingTentacle\Tentacle.config') }
end

### listening tentacle (without autoregister, no thumbprint):

describe service('OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10934) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "ListeningTentacleWithoutAutoRegister") do
  it { should exist }
  it { should_not be_registered_with_the_server }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\ListeningTentacleWithoutAutoRegister') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config') }
end

describe file('C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config') do
  it { should be_file }
  its(:content) { should_not match /Tentacle.Communication.TrustedOctopusServers/}
end

### listening tentacle (without autoregister, with thumbprint set):

describe service('OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10935) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "ListeningTentacleWithThumbprintWithoutAutoRegister") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_listening_tentacle }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name("ListeningTentacleWithThumbprintWithoutAutoRegister")}
  it { should have_policy('Default Machine Policy') }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\ListeningTentacleWithThumbprintWithoutAutoRegister') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config') }
end

describe file('C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config') do
  it { should be_file }
  its(:content) { should match /Tentacle\.Communication\.TrustedOctopusServers.*#{ENV['OctopusServerThumbprint']}/}
end

### listening tentacle with specific service account

describe service('OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('.\ServiceUser') }
end

describe port(10936) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "ListeningTentacleWithCustomAccount") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_listening_tentacle }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name('ListeningTentacleWithCustomAccount')}
  it { should have_policy('Default Machine Policy') }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\ListeningTentacleWithCustomAccount') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config') }
end

describe file('C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config') do
  it { should be_file }
  its(:content) { should match /Tentacle\.Communication\.TrustedOctopusServers.*#{ENV['OctopusServerThumbprint']}/}
end

#seq logging
describe file('C:/Program Files/Octopus Deploy/Tentacle/Seq.Client.NLog.dll') do
  it { should be_file }
end

describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe.nlog') do
  it { should be_file }
  its(:content) { should match /<add assembly="Seq.Client.NLog" \/>/ }
  its(:content) { should match /<logger name="\*" minlevel="Info" writeTo="seq" \/>/ }
  its(:content) { should match /<target name="seq" xsi:type="Seq" serverUrl="http:\/\/localhost\/seq" apiKey="MyMagicSeqApiKey">/ }
  its(:content) { should match /<property name="Application" value="Octopus" \/>/ }
  its(:content) { should match /<property name="Server" value="MyServer" \/>/ }
end

### DSC success
describe command('$ProgressPreference = "SilentlyContinue"; try { Get-DSCConfiguration -ErrorAction Stop; write-output "Get-DSCConfiguration succeeded"; $true } catch { write-output "Get-DSCConfiguration failed"; write-output $_; $false }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Get-DSCConfiguration succeeded/ }
end

describe command('$ProgressPreference = "SilentlyContinue"; try { if (-not (Test-DSCConfiguration -ErrorAction Stop)) { write-output "Test-DSCConfiguration returned false"; exit 1 } write-output "Test-DSCConfiguration succeeded"; exit 0 } catch { write-output "Test-DSCConfiguration failed"; write-output $_; exit 2 }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Test-DSCConfiguration succeeded/ }
end
