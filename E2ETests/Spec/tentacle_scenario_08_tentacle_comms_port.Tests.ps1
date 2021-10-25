describe tentacle_scenario_08_tentacle_comms_port {
  require 'json'

  config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/Applications" {
    Test-Path 'c:/Applications' -PathType Container | should -be $true
  }

  it "should have installed the binary" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' -PathType Leaf | should -be $true
  }

  it "should have installed a newer version" {
    # we should've upgraded past this
    (Get-Item 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe').VersionInfo.FileVersion | should -BeGreaterThan  [System.Version]::Parse('3.20.0')
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
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
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

    it "should have endpoint" {
        $tentacle.Endpoint | should -be "https://$($ENV:COMPUTERNAME):10900/"
    }
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\Tentacle' | should -be $true
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\Tentacle' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\\Program Files\\Octopus Deploy\\Tentacle\\"
  }

  it "should have created instance registry entry" {
    Test-Path 'HKLM:\Software\Octopus\Tentacle\Tentacle' | should -be $true
  }

  it "should have kept the ConfigurationFilePath" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\Tentacle\Tentacle' -Name "ConfigurationFilePath" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config"
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/Tentacle.config' -raw | ConvertFrom-Json -depth 10).ConfigurationFilePath | Should -be 'C:\Octopus\OctopusTentacleHome\Tentacle\Tentacle.config'
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

