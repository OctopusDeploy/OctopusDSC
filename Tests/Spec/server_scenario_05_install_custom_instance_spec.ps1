describe "server install custom instance" {
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
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name 'InstallLocation').InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
  }

  it "should have created 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config'" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' | Should -be $true
  }

  it "'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' should be a file" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' -PathType Leaf | Should -be $true
  }

  it "should have set 'ConfigurationFilePath' to 'C:\\\\Octopus\\\\OctopusServer-MyOctopusServer.config' in 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' -Raw | Should -match "`"ConfigurationFilePath`": `"C:\\\\Octopus\\\\OctopusServer-MyOctopusServer.config`""
  }

  it "should have set 'Name' to 'MyOctopusServer' in 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' -Raw | Should -match "`"Name`": `"MyOctopusServer`""
  }

  it "should have registed the 'OctopusDeploy: MyOctopusServer' service" {
    (Get-Service 'OctopusDeploy: MyOctopusServer' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy: MyOctopusServer' service" {
    (Get-Service 'OctopusDeploy: MyOctopusServer' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy: MyOctopusServer' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy: MyOctopusServer' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy: MyOctopusServer' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy: MyOctopusServer'").StartName | Should -be 'LocalSystem'
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
