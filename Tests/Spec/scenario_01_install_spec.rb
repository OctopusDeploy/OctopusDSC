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

describe service('OctopusDeploy Tentacle') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  #todo: add matcher for service name
end

describe port(10933) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey']) do
  it { should be_registered_with_the_server }
  # disabled for now - we are registering as a passive tentacle, but we are not publically
  # accessible from the server, so we register okay, but dont come online.
  #it { should be_online }
  it { should be_in_environment('The Environment') }
  it { should have_role('Test-Tentacle') }
end
