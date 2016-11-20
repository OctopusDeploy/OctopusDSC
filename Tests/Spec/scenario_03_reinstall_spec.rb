require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/Applications') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe') do
  it { should be_file }
  it { should have_version('3.3.24.0') }
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

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Tentacle") do
  it { should be_registered_with_the_server }
  # disabled for now - we are registering as a passive tentacle, but we are not publically
  # accessible from the server, so we register okay, but dont come online.
  #it { should be_online }
  it { should be_in_environment('The Environment') }
  it { should have_role('Test-Tentacle') }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Tentacle\\") }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\Tentacle\Tentacle.config') }
end
