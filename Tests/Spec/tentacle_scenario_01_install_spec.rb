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
  it { should have_display_name('My Listening Tentacle')}
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
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\ListeningTentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\ListeningTentacle\Tentacle.config') }
end

### polling tentacle:

describe service('OctopusDeploy Tentacle: PollingTentacle') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
  it { should have_display_name("#{ENV['COMPUTERNAME']}_PollingTentacle")}
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "PollingTentacle") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_in_environment('The-Env') }
  it { should have_role('Test-Tentacle') }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\PollingTentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\PollingTentacle\Tentacle.config') }
end
