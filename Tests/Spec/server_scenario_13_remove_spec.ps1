describe "server remove (take 3)" {
    #we deliberately dont cleanup the octopus directory, as it contains logs & config
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "the file 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' should not exist" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | Should -be $false
  }

  it "the service 'OctopusDeploy' should not be installed" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end

  # describe port(10943) do
  #   it { should_not be_listening.with('tcp') }
  # end

  # describe port(81) do
  #   it { should_not be_listening.with('tcp') }
  # end

  # #todo: confirm whether these should be deleted
  # # describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  # #   it { should_not exist }
  # # end

  # # describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
  # #   it { should_not exist }
  # # end
}
