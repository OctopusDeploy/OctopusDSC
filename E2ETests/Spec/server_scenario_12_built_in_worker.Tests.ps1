describe server_scenario_12_built_in_worker {

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/Octopus/Artifacts" {
    Test-Path 'c:/Octopus/Artifacts' -PathType Container | should -be $true
  }

  it "should have created c:/Octopus/Logs" {
    Test-Path 'c:/Octopus/Logs' -PathType Container | should -be $true
  }

  it "should have created c:/Octopus/TaskLogs" {
    Test-Path 'c:/Octopus/TaskLogs' -PathType Container | should -be $true
  }

  it "should have created C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Leaf | should -be $true
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
  }

  it "should have created the config file" {
    Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -PathType Leaf | should -be $true
  }

  it "should have set 'ConfigurationFilePath' in the config file" {
    $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -raw
    $contents | should -match '"ConfigurationFilePath": "C:\\\\Octopus\\\\OctopusServer-OctopusServer.config"'
  }

  it "should have set 'Name' in the config file" {
    $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -raw
    $contents | should -match '"Name": "OctopusServer"'
  }

  it "should have created the OctoSquid user" {
      Get-LocalUser 'OctoSquid' -ErrorAction SilentlyContinue | should -not -be $null
  }

  it "should have added OctoSquid to local administrators" {
    (Get-LocalGroupMember "Administrators").Name -contains "$env:COMPUTERNAME\OctoSquid" | should -be $true
  }

  it "should have created the OctoMollusc user" {
    Get-LocalUser 'OctoMollusc' -ErrorAction SilentlyContinue | should -not -be $null
  }

  it "should not have added octoMollusc to the local administrators group" {
    (Get-LocalGroupMember "Administrators").Name -contains "$env:COMPUTERNAME\OctoMollusc" | should -be $false
  }

  it "should have created the service" {
    Get-Service 'OctopusDeploy' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy'").StartName | should -be '.\OctoSquid'
  }

  it "should set the BuiltInWorker.CustomAccountUserName" {
    $ProgressPreference = "SilentlyContinue"
    $response = (& "C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" show-configuration --instance OctopusServer --format json-hierarchical | out-string | ConvertFrom-Json)
    $LASTEXITCODE | Should -be 0
    $response.Octopus.BuiltInWorker.CustomAccountUserName | Should -be "OctoMollusc"
  }

  it "should be listening on port 10943" {
    (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  it "should be listening on port 81" {
    (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

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

  Describe "Get-DSCConfigurationStatus" {
      BeforeDiscovery {
        $status = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)[0]
        $resourceStates = @($status.ResourcesInDesiredState + $status.ResourcesNotInDesiredState) | where-object { $null -ne $_ }
      }

      It "should have succeeded" {
        $status = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)[0]
        $status.Status | Should -be "Success"
      }

      It "should have applied <_.ResourceId> correctly" -ForEach $resourceStates {
        $_.InDesiredState | should -be $true
      }

      It "should have not received any errors from <_.ResourceId>" -ForEach $resourceStates {
        $_.Error | should -be $null
      }
  }
}

