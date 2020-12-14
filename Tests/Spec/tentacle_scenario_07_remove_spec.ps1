describe "tentacle remove (take 2)" {
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/Applications'" {
    Test-Path 'c:/Applications' | Should -be $true
  }

  it "the file 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' should not exist" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | Should -be $false
  }

  it "the service 'OctopusDeploy Tentacle' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # should reg entry be deleted?
  # should instance file be deleted?

  describe windows_dsc do
    it { should be_able_to_get_dsc_configuration }
    it { should have_test_dsc_configuration_return_true }
    it { should have_dsc_configuration_status_of_success }
  end
}
