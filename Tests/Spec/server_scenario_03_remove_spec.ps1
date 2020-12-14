describe "server remove" {
    #we deliberately dont cleanup the octopus directory, as it contains logs & config
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should not have removed created 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe'" {
    # as there is another instance still on the box - we shouldn't have removed the binaries
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | Should -be $true
  }

  it "the service 'OctopusDeploy' should not be installed" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue) | Should -be $null
  }

  describe windows_dsc do
    it { should be_able_to_get_dsc_configuration }
    it { should have_test_dsc_configuration_return_true }
    it { should have_dsc_configuration_status_of_success }
  end

  describe port(10943) do
    it { should_not be_listening.with('tcp') }
  end

  describe port(81) do
    it { should_not be_listening.with('tcp') }
  end

  #todo: confirm whether these should be deleted
  # describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  #   it { should_not exist }
  # end

  # describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
  #   it { should_not exist }
  # end
}
