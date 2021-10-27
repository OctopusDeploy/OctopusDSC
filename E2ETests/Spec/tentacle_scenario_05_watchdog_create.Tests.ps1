describe tentacle_scenario_05_watchdog_create {
  it "should have installed the watchdog" {
    $ProgressPreference = "SilentlyContinue"
    $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration --format json-hierarchical | out-string | ConvertFrom-Json)
    $LASTEXITCODE | Should -be 0
    $response.Octopus.Watchdog.Enabled | should -be "True"
    $response.Octopus.Watchdog.Interval | should -be "10"
    $response.Octopus.Watchdog.Instances | should -be "*"
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

