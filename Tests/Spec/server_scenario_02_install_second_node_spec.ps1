describe "server install second node" {
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/ChezOctopusSecondNode'" {
    Test-Path 'c:/ChezOctopusSecondNode' | Should -be $true
  }

  it "should have created 'c:/ChezOctopus/Artifacts'" {
    Test-Path 'c:/ChezOctopus/Artifacts' | Should -be $true
  }

  it "should not have created 'c:/ChezOctopusSecondNode/Artifacts'" {
    Test-Path 'c:/ChezOctopusSecondNode/Artifacts' | Should -be $false
  }

  it "should have created 'c:/ChezOctopusSecondNode/Logs'" {
    # node logs go in the local instance folder
    Test-Path 'c:/ChezOctopusSecondNode/Logs' | Should -be $true
  }

  it "should have created 'c:/ChezOctopus/TaskLogs'" {
    Test-Path 'c:/ChezOctopus/TaskLogs' | Should -be $true
  }

  it "should not have created 'c:/ChezOctopusSecondNode/TaskLogs'" {
    # they should be pointed at c:/ChezOctopus/TaskLogs
    Test-Path 'c:/ChezOctopusSecondNode/TaskLogs' | Should -be $false
  }

  # unfortunately, cant test the packages folder at this point - its non determinate when it gets created

  # describe file('c:/ChezOctopus/Packages') do
  #   it { should be_directory }
  # end

  # describe file('c:/ChezOctopusSecondNode/Packages') do
  #   it { should_not be_directory } # they should be pointed at c:/ChezOctopus/Packages
  # end

  it "should have created 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe'" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | Should -be $true
  }

  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer'" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | Should -be $true
  }

  it "should have set 'InstallLocation' to 'C:\\Program Files\\Octopus Deploy\\Octopus\\'" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name 'InstallLocation').InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
  }

  it "should have created 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config'" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' | Should -be $true
  }

  it "'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' should be a file" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' -PathType Leaf | Should -be $true
  }

  it "should have set 'ConfigurationFilePath' to 'C:\\\\Octopus\\\\OctopusServer-HANode.config' in 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' -Raw | Should -match "`"ConfigurationFilePath`": `"C:\\\\Octopus\\\\OctopusServer-HANode.config`""
  }

  it "should have set 'Name' to 'HANode' in 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config'" {
    Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' -Raw | Should -match "`"Name`": `"HANode`""
  }

  it "should have registed the 'OctopusDeploy: HANode' service" {
    (Get-Service 'OctopusDeploy: HANode' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy: HANode' service" {
    (Get-Service 'OctopusDeploy: HANode' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy: HANode' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy: HANode' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy: HANode' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy: HANode'").StartName | Should -be 'LocalSystem'
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

  # #dsc overall status
  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
