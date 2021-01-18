describe "tentacle upgrade" {
  # config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/Applications'" {
    Test-Path 'c:/Applications' | Should -be $true
  }

  it "'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' should be a file" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' -PathType Leaf | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe') do
  #   #todo: maybe we should have a matcher "it {should have_version_newer_than('3.3.24.0')}"
  #   it { should_not have_version('3.3.24.0') } # we should've upgraded past this
  # end

  it "should have registed the 'OctopusDeploy Tentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle' -ErrorAction SilentlyContinue).StartMode | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10933) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "Tentacle") do
  #   it { should exist }
  #   it { should be_registered_with_the_server }
  #   it { should be_online }
  #   it { should be_listening_tentacle }
  #   it { should be_in_environment('The-Env') }
  #   it { should have_role('Test-Tentacle') }
  #   it { should have_policy('Default Machine Policy') }
  # end

  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle'" {
    Get-Item 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle' | Should -be $true
  }

  it "should have set 'InstallLocation' to 'C:\\Program Files\\Octopus Deploy\\Tentacle\\'" {
    Get-ItemProperty -Path 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle' -Name 'InstallLocation' | Should -be "C:\\Program Files\\Octopus Deploy\\Tentacle\\"
  }

  # reg entry sticks around for backwards compat
  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle'" {
    Get-Item 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle' | Should -be $true
  }

  it "should have set 'ConfigurationFilePath' to 'C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config'" {
    Get-ItemProperty -Path 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle' -Name 'ConfigurationFilePath' | Should -be 'C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config'
  }

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config')
  # config_json = JSON.parse(config_file)
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config') }
  # end

  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
