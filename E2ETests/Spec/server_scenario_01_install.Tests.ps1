describe server_scenario_01_install {
  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/ChezOctopus" {
    Test-Path 'c:/ChezOctopus' -PathType Container | should -be $true
  }

  it "should have created c:/ChezOctopus/Artifacts" {
    Test-Path 'c:/ChezOctopus/Artifacts' -PathType Container | should -be $true
  }

  it "should have created c:/ChezOctopus/Logs" {
    Test-Path 'c:/ChezOctopus/Logs' -PathType Container | should -be $true
  }

  it "should have created c:/ChezOctopus/TaskLogs" {
    Test-Path 'c:/ChezOctopus/TaskLogs' -PathType Container | should -be $true
  }

  it "should have created C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Leaf | should -be $true
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
  }

  it "should have set the InstallLocation" {
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
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10943" {
    (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  it "should be listening on port 81" {
    (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  it "should be listening on port 443" {
    (Get-NetTCPConnection -LocalPort 443 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  describe "Environment: Production" {
    BeforeAll {
      foreach($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
        . $import.fullname
      }

      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $environment = Get-EnvironmentDetails $config.OctopusServerUrl $config.OctopusApiKey "Production"
    }

    it "should exist" {
      $environment.Exists | Should -be $true
    }
  }

  describe "Space: Integration Team" {
    BeforeAll {
      foreach($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
        . $import.fullname
      }

      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $space = Get-SpaceDetails $config.OctopusServerUrl $config.OctopusApiKey "Integration Team"
    }

    it "should exist" {
      $space.Exists | Should -be $true
    }

    it "should have description 'Description for the Integration Team Space'" {
        $space.Description | Should -be 'Description for the Integration Team Space'
      }
  }

  describe "WorkerPool: Secondary Worker Pool" {
    BeforeAll {
      foreach($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
        . $import.fullname
      }

      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $workerPool = Get-WorkerPoolDetails $config.OctopusServerUrl $config.OctopusApiKey "Secondary Worker Pool"
    }

    it "should exist" {
      $workerPool.Exists | Should -be $true
    }
  }

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
