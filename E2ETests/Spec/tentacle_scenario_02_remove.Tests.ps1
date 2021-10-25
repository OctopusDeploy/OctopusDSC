describe tentacle_scenario_02_remove {
  require 'json'

  config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  #we deliberately dont cleanup the octopus directory, as it contains logs & config
  it "should have left c:/Octopus alone" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/Applications" {
    Test-Path 'c:/Applications' -PathType Container | should -be $true
  }

  it "should have removed C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | should -be $false
  }

  it "should have removed OctopusDeploy Tentacle: ListeningTentacle" {
    Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' -ErrorAction SilentlyContinue | should -be $null
  }

  # Listening Tentacle
  describe "Tentacle: ListeningTentacle" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "ListeningTentacle"
    }

    it "should not exist" {
      $tentacle.Exists | Should -be $false
    }
  }

  it "should not be listening on port 10933" {
    (Get-NetTCPConnection -LocalPort 10933 -ErrorAction SilentlyContinue).State | should -be $null
  }

  # Polling Tentacle
  it "should have removed OctopusDeploy Tentacle: PollingTentacle" {
    Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue | should -be $null
  }

  describe "Tentacle: PollingTentacle" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "PollingTentacle"
    }

    it "should not exist" {
      $tentacle.Exists | Should -be $false
    }
  }

  # Polling Tentacle with autoregister disabled
  it "should have removed OctopusDeploy Tentacle: PollingTentacleWithoutAutoRegister" {
    Get-Service 'OctopusDeploy Tentacle: PollingTentacleWithoutAutoRegister' -ErrorAction SilentlyContinue | should -be $null
  }

  describe "Tentacle: PollingTentacleWithoutAutoRegister" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "PollingTentacleWithoutAutoRegister"
    }

    it "should not exist" {
      $tentacle.Exists | Should -be $false
    }
  }

  # Polling Tentacle with autoregister disabled but thumbprint set
  it "should have removed OctopusDeploy Tentacle: PollingTentacleWithThumbprintWithoutAutoRegister" {
    Get-Service 'OctopusDeploy Tentacle: PollingTentacleWithThumbprintWithoutAutoRegister' -ErrorAction SilentlyContinue | should -be $null
  }

  describe "Tentacle: PollingTentacleWithThumbprintWithoutAutoRegister" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "PollingTentacleWithThumbprintWithoutAutoRegister"
    }

    it "should not exist" {
      $tentacle.Exists | Should -be $false
    }
  }

  # Worker Tentacle
  it "should have removed OctopusDeploy Tentacle: WorkerTentacle" {
    Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' -ErrorAction SilentlyContinue | should -be $null
  }

#   describe octopus_deploy_worker(config['OctopusServerUrl'], config['OctopusApiKey'], "WorkerTentacle") do
#     it { should_not exist }
#   end

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

  it "should get Success back from Get-DSCConfigurationStatus"
  {
    $ProgressPreference = "SilentlyContinue"
    $statuses = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)
    $statuses[0].Status | Should -be "Success"
  }

  #todo: can we check its been removed from the server somehow?
}

