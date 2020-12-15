describe "tentacle watchdog delete" {
  it "should report that watchdog is disabled" {
    $ProgressPreference = "SilentlyContinue";
    $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration --format json-hierarchical | out-string | ConvertFrom-Json);
    $response.Octopus.Watchdog.Enabled | Should -be $false
  }

  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
