describe "server re-install" {
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' should be a file" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Leaf | Should -be $true
  }

  it "should have installed version '2018.12.1'" {
    $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe')
    $version.FileVersion | Should -be '2018.12.1'
  }

  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer'" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | Should -be $true
  }

  it "should have set 'InstallLocation' to 'C:\\Program Files\\Octopus Deploy\\Octopus\\'" {
    Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name 'InstallLocation' | Should -be "C:\\Program Files\\Octopus Deploy\\Octopus\\"
  }

  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer'" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer\OctopusServer' | Should -be $true
  }

  it "should have set 'ConfigurationFilePath' to 'C:\Octopus\OctopusServer-OctopusServer.config'" {
    Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer\OctopusServer' -Name 'ConfigurationFilePath' | Should -be 'C:\Octopus\OctopusServer-OctopusServer.config'
  }

  it "should have registed the 'OctopusDeploy' service" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy' service" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue).StartMode | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10943) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe port(81) do
  #   it { should be_listening.with('tcp') }
  # end

  # #environment
  # describe octopus_deploy_environment(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "UAT 1") do
  #   it { should exist }
  # end

  # #dsc overall status
  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
