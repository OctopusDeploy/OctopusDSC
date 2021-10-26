describe server_scenario_02_install_second_node {

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/ChezOctopusSecondNode" {
    Test-Path 'c:/ChezOctopusSecondNode' -PathType Container | should -be $true
  }

  it "should have created c:/ChezOctopus/Artifacts" {
    Test-Path 'c:/ChezOctopus/Artifacts' -PathType Container | should -be $true
  }

  it "should not store artifacts under the home directory" {
    # they should be pointed at c:/ChezOctopus/
    Test-Path 'c:/ChezOctopusSecondNode/Artifacts' | should -be $false
  }

  it "should store logs in the local instance folder" {
    # node logs go in the local instance folder
    Test-Path 'c:/ChezOctopusSecondNode/Logs' | should -be $true
  }

  it "should have created c:/ChezOctopus/TaskLogs" {
    Test-Path 'c:/ChezOctopus/TaskLogs' -PathType Container | should -be $true
  }

  it "should not store task logs under the home directory" {
      # they should be pointed at c:/ChezOctopus/TaskLogs
    Test-Path 'c:/ChezOctopusSecondNode/TaskLogs' | should -be $false
  }

  it "should have created C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Leaf | should -be $true
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
  }

  it "should have set the install location" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
  }

  it "should have created the config file" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' -PathType Leaf | should -be $true
  }

  it "should have set 'ConfigurationFilePath' in the config file" {
    $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' -raw
    $contents | should -match '"ConfigurationFilePath": "C:\\\\Octopus\\\\OctopusServer-HANode.config"'
  }

  it "should have set 'Name' in the config file" {
    $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/HANode.config' -raw
    $contents | should -match '"Name": "HANode"'
  }

  it "should have created the service" {
    Get-Service 'OctopusDeploy: HANode' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy: HANode').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy: HANode').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy: HANode'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10943" {
    (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  it "should be listening on port 81" {
    (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  #environment
#   describe octopus_deploy_environment(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Production") do
#     it { should exist }
#   end

  #dsc overall status
  it "should be able to get dsc configuration" {
    $ProgressPreference = "SilentlyContinue"
    $state = ""
    do
   {
      $state = (Get-DscLocalConfigurationManager).LCMState
      write-verbose "LCM state is $state"
      Start-Sleep -Seconds 2
    } while ($state -ne "Idle")

    Get-DSCConfiguration -ErrorAction Stop
  }

  it "should get true back from Test-DSCConfiguraiton" {
    $ProgressPreference = "SilentlyContinue"
    $state = ""
    do
    {
      $state = (Get-DscLocalConfigurationManager).LCMState
      write-verbose "LCM state is $state"
      Start-Sleep -Seconds 2
    } while ($state -ne "Idle")
    Test-DSCConfiguration -ErrorAction Stop | should -be $true
  }

  it "should get Success back from Get-DSCConfigurationStatus" {
    $ProgressPreference = "SilentlyContinue"
    $statuses = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)
    $statuses[0].Status | Should -be "Success"
  }
}

