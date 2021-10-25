describe tentacle_scenario_07_remove {

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/Applications" {
    Test-Path 'c:/Applications' -PathType Container | should -be $true
  }

  it "should have removed C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | should -be $false
  }

  it "should have removed OctopusDeploy Tentacle" {
    Get-Service 'OctopusDeploy Tentacle' -ErrorAction SilentlyContinue | should -be $null
  }

  # should reg entry be deleted?
  # should instance file be deleted?

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
