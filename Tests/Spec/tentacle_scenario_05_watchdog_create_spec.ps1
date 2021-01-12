describe "tentacle watchdog create" {
  it "should report that watchdog is enabled" {
    $ProgressPreference = "SilentlyContinue";
    $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration | out-string | ConvertFrom-Json);
    $response.Octopus.Watchdog.Enabled | Should -be $true
  }

  it "should report that watchdog is running at an interval of 10 minutes" {
    $ProgressPreference = "SilentlyContinue";
    $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration | out-string | ConvertFrom-Json);
    $response.Octopus.Watchdog.Interval | Should -be 10
  }

  it "should report that watchdog is watching all instances" {
    $ProgressPreference = "SilentlyContinue";
    $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration | out-string | ConvertFrom-Json);
    $response.Octopus.Watchdog.Instances | should -be '*'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
