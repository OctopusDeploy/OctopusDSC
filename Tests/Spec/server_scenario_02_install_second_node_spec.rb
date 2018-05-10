require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/ChezOctopusSecondNode') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/Logs') do
  it { should be_directory }
end

describe file('c:/ChezOctopusSecondNode/Logs') do
  it { should_not be_directory }
end

describe file('c:/ChezOctopus/Artifacts') do
  it { should be_directory }
end

describe file('c:/ChezOctopusSecondNode/Artifacts') do
  it { should_not be_directory } # they should be pointed at c:/ChezOctopus/ 
end

describe file('c:/ChezOctopus/TaskLogs') do
  it { should be_directory }
end

describe file('c:/ChezOctopusSecondNode/TaskLogs') do
  it { should_not be_directory } # they should be pointed at c:/ChezOctopus/TaskLogs 
end

# unfortunately, cant test the packages folder at this point - its non determinate when it gets created

# describe file('c:/ChezOctopus/Packages') do
#   it { should be_directory }
# end

# describe file('c:/ChezOctopusSecondNode/Packages') do
#   it { should_not be_directory } # they should be pointed at c:/ChezOctopus/Packages 
# end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Octopus\\") }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\HANode') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\OctopusServer-HANode.config') }
end

describe service('OctopusDeploy: HANode') do
  it { should be_installed }
  it { should be_running }
  it { should have_start_mode('Automatic') }
  it { should run_under_account('LocalSystem') }
end

describe port(10943) do
  it { should be_listening.with('tcp') }
end

describe port(81) do
  it { should be_listening.with('tcp') }
end

#environment
describe octopus_deploy_environment(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Production") do
  it { should exist }
end

#seq logging
describe file('C:/Program Files/Octopus Deploy/Octopus/Seq.Client.NLog.dll') do
  it { should be_file }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe.nlog') do
  it { should be_file }
  its(:content) { should match /<add assembly="Seq.Client.NLog" \/>/ }
  its(:content) { should match /<logger name="\*" minlevel="Info" writeTo="seq" \/>/ }
  its(:content) { should match /<target name="seq" xsi:type="Seq" serverUrl="http:\/\/localhost\/seq" apiKey="MyMagicSeqApiKey">/ }
  its(:content) { should match /<property name="Application" value="Octopus" \/>/ }
  its(:content) { should match /<property name="Server" value="MyServer" \/>/ }
end

#dsc overall status
describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
