describe tentacle_scenario_05_watchdog_create {
  it "should have installed the watchdog" {
    $ProgressPreference = "SilentlyContinue"
    $response = (& "C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" show-configuration --format json-hierarchical | out-string | ConvertFrom-Json)
    $LASTEXITCODE | Should -be 0
    $response.Octopus.Watchdog.Enabled | should -be "True"
    $response.Octopus.Watchdog.Interval | should be "10"
    $response.Octopus.Watchdog.Instances | should be "*"
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

