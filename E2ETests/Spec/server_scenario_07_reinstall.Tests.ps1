describe server_scenario_07_reinstall {

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have installed C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | should -be $true
  }

  it "should have version 2018.12.1" {
    (Get-Item 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe').VersionInfo.FileVersion | should -be '2018.12.1'
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
  }

  it "should have set the InstallLocation" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
  }

  it "should have created instance registry entry" {
    Test-Path 'HKLM:\Software\Octopus\OctopusServer\OctopusServer' | should -be $true
  }

  it "should have set the ConfigurationFilePath" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer\OctopusServer' -Name "ConfigurationFilePath" -ErrorAction SilentlyContinue).ConfigurationFilePath | Should -be "C:\Octopus\OctopusServer-OctopusServer.config"
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

  describe "Environment: UAT 1" {
    BeforeAll {
      foreach($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
        . $import.fullname
      }

      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $environment = Get-EnvironmentDetails $config.OctopusServerUrl $config.OctopusApiKey "UAT 1"
    }

    it "should exist" {
      $environment.Exists | Should -be $true
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

  Describe "Get-DSCConfigurationStatus" {
      BeforeDiscovery {
        $status = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)[0]
        $resourceStates = @($status.ResourcesInDesiredState + $status.ResourcesNotInDesiredState)
      }

      It "should have succeeded" {
          $status.Status | Should -be "Success"
      }

      It "should have applied <ResourceId> correctly" -ForEach $resourceStates {
        $_.InDesiredState | should -be $true
      }

      It "should have not received any errors from <ResourceId>" -ForEach $resourceStates {
        $_.Error | should -be $null
      }
  }
}

