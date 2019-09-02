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

describe file('C:/ProgramData/Octopus/Tentacle/Instances') do
  it { should be_directory }
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
  it { should have_tenanted_deployment_participation('TenantedOrUntenanted') }
end

describe file('C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config')
config_json = JSON.parse(config_file) # add check for nil
describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\ListeningTentacleHome\ListeningTentacle\Tentacle.config') }
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

describe file('C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config')
config_json = JSON.parse(config_file)

describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\Polling Tentacle Home\PollingTentacle\Tentacle.config') }
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

describe file('C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config')
config_json = JSON.parse(config_file)
describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config') }
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

describe file('C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config')
config_json = JSON.parse(config_file)
describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle\Tentacle.config') }
end

describe file('C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config') do
  it { should be_file }
  its(:content) { should match /Tentacle\.Communication\.TrustedOctopusServers.*#{ENV['OctopusServerThumbprint']}/}
end

### worker tentacle

describe service('OctopusDeploy Tentacle: WorkerTentacle') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10937) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "WorkerTentacle") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_listening_tentacle }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
  it { should have_display_name("My Worker Tentacle")}
  # TODO check pool membership
end

describe file('C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config')
config_json = JSON.parse(config_file)
describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config') }
end

describe file('C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config') do
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

describe file('C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config') do
  it { should be_file }
end

config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config')
config_json = JSON.parse(config_file)
describe config_json['ConfigurationFilePath'] do
  it { should eq('C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config') }
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
  its(:content) { should match /<logger name="\*" minlevel="Info" writeTo="seqbufferingwrapper" \/>/ }
  its(:content) { should match /<target name=\"seqbufferingwrapper\" xsi:type=\"BufferingWrapper\" bufferSize=\"1000\" flushTimeout=\"2000\">/}
  its(:content) { should match /<target name="seq" xsi:type="Seq" serverUrl="http:\/\/localhost\/seq" apiKey="MyMagicSeqApiKey">/ }
  its(:content) { should match /<property name="Application" value="Octopus" \/>/ }
  its(:content) { should match /<property name="Server" value="MyServer" \/>/ }
end

### DSC success
describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
