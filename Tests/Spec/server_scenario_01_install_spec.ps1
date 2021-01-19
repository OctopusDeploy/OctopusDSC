describe "server install" {
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/ChezOctopus'" {
    Test-Path 'c:/ChezOctopus' | Should -be $true
  }

  it "should have created 'c:/ChezOctopus/Artifacts'" {
    Test-Path 'c:/ChezOctopus/Artifacts' | Should -be $true
  }

  it "should have created 'c:/ChezOctopus/Logs'" {
    Test-Path 'c:/ChezOctopus/Logs' | Should -be $true
  }

  it "should have created 'c:/ChezOctopus/TaskLogs'" {
    Test-Path 'c:/ChezOctopus/TaskLogs' | Should -be $true
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
  # describe octopus_deploy_environment(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Production") do
  #   it { should exist }
  # end

  # #space
  # describe octopus_deploy_space(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], 'Integration Team') do
  #   it { should exist }
  #   it { should have_description('Description for the Integration Team Space') }
  # end

  # #worker pool
  # describe octopus_deploy_worker_pool(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Secondary Worker Pool") do
  #   it { should exist }
  # end

  # #dsc overall status
  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
