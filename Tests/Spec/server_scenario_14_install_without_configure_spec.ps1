describe "server install without configure" {
  # from previous install
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe'" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | Should -be $true
  }

  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer'" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | Should -be $true
  }

  it "should have set 'InstallLocation' to 'C:\\Program Files\\Octopus Deploy\\Octopus\\'" {
    Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name 'InstallLocation' | Should -be "C:\\Program Files\\Octopus Deploy\\Octopus\\"
  }

  #describe windows_registry_key('HKLM:\Software\Octopus\OctopusServer\OctopusServer') do
  #  it { should_not exist }
  #end

  it "the file 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' should not exist" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' | Should -be $false
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
}
