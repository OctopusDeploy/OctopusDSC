describe tentacle_scenario_03_reinstall {
  require 'json'

  config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/Applications" {
    Test-Path 'c:/Applications' -PathType Container | should -be $true
  }

  it "should have installed C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | should -be $true
  }

  it "should have version 3.20.0.0" {
    (Get-Item 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe').VersionInfo.FileVersion | should -be '3.20.0.0'
  }

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10933" {
    (Get-NetTCPConnection -LocalPort 10933 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  describe "Tentacle: Tentacle" {
    BeforeDiscovery {
      foreach($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
        . $import.fullname
      }
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "Tentacle"
    }

    it "should exist" {
      $tentacle.Exists | Should -be $true
    }

    it "should be registered with the server" {
      $tentacle.IsRegisteredWithTheServer | Should -be $true
    }

    it "should be online" {
      $tentacle.IsOnline | Should -be $true
    }

    it "should be a listening tentacle" {
      $tentacle.IsListening | Should -be $true
    }

    it "should be in environment 'The-Env'" {
      $tentacle.Environments -contains 'The-Env' | Should -be $true
    }

    it "should have role 'Test-Tentacle'" {
      $tentacle.Roles -contains 'Test-Tentacle' | should -be $true
    }

    it "should not be assigned to any tenants" {
      $tentacle.Tenants.length | should -be 0
    }

    it "should not have any tenant tags" {
      $tentacle.TenantTags.length | should -be 0
    }

    it "should have policy 'Default Machine Policy'" {
      $tentacle.Policy | should -be 'Default Machine Policy'
    }
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\Tentacle' | should -be $true
  }

  it "should have set the InstallLocation" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\Tentacle' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\\Program Files\\Octopus Deploy\\Tentacle\\"
  }

  it "should have created instance registry entry" {
    Test-Path 'HKLM:\Software\Octopus\Tentacle\Tentacle' | should -be $true
  }

  it "should have set the ConfigurationFilePath" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\Tentacle\Tentacle' -Name "ConfigurationFilePath" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config"
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

  it "should get Success back from Get-DSCConfigurationStatus" {
    $ProgressPreference = "SilentlyContinue"
    $statuses = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)
    $statuses[0].Status | Should -be "Success"
  }
}

