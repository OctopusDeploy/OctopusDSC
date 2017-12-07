require 'spec_helper'

describe command('$ProgressPreference = "SilentlyContinue"; $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration | out-string | ConvertFrom-Json); write-output "$($response.Octopus.Watchdog.Enabled)"') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /False/ }
end

describe windows_dsc do
  it { should be_able_to_get_dsc_configuration }
  it { should have_applied_dsc_configuration_successfully }
end
