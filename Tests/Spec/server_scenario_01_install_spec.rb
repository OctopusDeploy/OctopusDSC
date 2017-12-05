require 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('c:/ChezOctopus') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/Artifacts') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/Logs') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/OctopusServer') do
  it { should be_directory }
end

describe file('c:/ChezOctopus/TaskLogs') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Octopus\\") }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\OctopusServer.config') }
end

describe service('OctopusDeploy') do
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
describe command('$ProgressPreference = "SilentlyContinue"; try { Get-DSCConfiguration -ErrorAction Stop; write-output "Get-DSCConfiguration succeeded"; $true } catch { write-output "Get-DSCConfiguration failed"; write-output $_; $false }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Get-DSCConfiguration succeeded/ }
end

describe command('$ProgressPreference = "SilentlyContinue"; try { if (-not (Test-DSCConfiguration -ErrorAction Stop)) { write-output "Test-DSCConfiguration returned false"; exit 1 } write-output "Test-DSCConfiguration succeeded"; exit 0 } catch { write-output "Test-DSCConfiguration failed"; write-output $_; exit 2 }') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Test-DSCConfiguration succeeded/ }
end
