describe "server configure pre-installed instance" {

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
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name 'InstallLocation').InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
  }

  it "should have created 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config'" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config' | Should -be $true
  }

  it "'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config' should be a file" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config' -PathType Leaf | Should -be $true
  }

  it "should have set 'ConfigurationFilePath' to 'C:\\\\Octopus\\\\OctopusServer-ConfigurePreInstalledInstance.config' in 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config' -Raw | Should -match "`"ConfigurationFilePath`": `"C:\\\\Octopus\\\\OctopusServer-ConfigurePreInstalledInstance.config`""
  }

  it "should have set 'Name' to 'ConfigurePreInstalledInstance' in 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/ConfigurePreInstalledInstance.config' -Raw | Should -match "`"Name`": `"ConfigurePreInstalledInstance`""
  }


  it "should have registed the 'OctopusDeploy: ConfigurePreInstalledInstance' service" {
    (Get-Service 'OctopusDeploy: ConfigurePreInstalledInstance' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy: ConfigurePreInstalledInstance' service" {
    (Get-Service 'OctopusDeploy: ConfigurePreInstalledInstance' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy: ConfigurePreInstalledInstance' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy: ConfigurePreInstalledInstance' -ErrorAction SilentlyContinue).StartMode | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy: ConfigurePreInstalledInstance' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy: ConfigurePreInstalledInstance'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
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
