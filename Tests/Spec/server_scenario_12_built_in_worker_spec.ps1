describe "server built-in worker" {
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/Octopus/Artifacts'" {
    Test-Path 'c:/Octopus/Artifacts' | Should -be $true
  }

  it "should have created 'c:/Octopus/Logs'" {
    Test-Path 'c:/Octopus/Logs' | Should -be $true
  }

  it "should have created 'c:/Octopus/TaskLogs'" {
    Test-Path 'c:/Octopus/TaskLogs' | Should -be $true
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

  it "should have created 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config'" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' | Should -be $true
  }

  it "'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' should be a file" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -PathType Leaf | Should -be $true
  }

  it "should have set 'ConfigurationFilePath' to 'C:\\\\Octopus\\\\OctopusServer-OctopusServer.config' in 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -Raw | Should -match "`"ConfigurationFilePath`": `"C:\\\\Octopus\\\\OctopusServer-OctopusServer.config`""
  }

  it "should have set 'Name' to 'OctopusServer' in 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -Raw | Should -match "`"Name`": `"OctopusServer`""
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe user('OctoSquid') do
  #   it { should exist }
  #   it { should belong_to_group('Administrators')}
  # end

  # describe user('OctoMollusc') do
  #   it { should exist }
  #   it { should_not belong_to_group('Administrators')}
  # end

  it "should have registed the 'OctopusDeploy' service" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy' service" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue).StartMode | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy' service to run under '.\OctoSquid'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy'").StartName | Should -be '.\OctoSquid'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe command('& "C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" show-configuration --instance OctopusServer --format xml') do
  #   its(:exit_status) { should eq 0 }
  #   its(:stdout) { should match /<set key="Octopus.BuiltInWorker.CustomAccountUserName">OctoMollusc<\/set>/ }
  # end

  # describe port(10943) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe port(81) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
