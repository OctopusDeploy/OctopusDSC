describe server_scenario_03_remove {
  #we deliberately dont cleanup the octopus directory, as it contains logs & config
  it "should have left c:/Octopus alone" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have left the executable there" {
      # as there is another instance still on the box - we shouldn't have removed the binaries
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Container | should -be $true
  }

  it "should have uninstalled the service" {
    (Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue) | should -be $null
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

  it "should not be listening on port 10943" {
    (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State | should -be $null
  }

  it "should not be listening on port 81" {
    (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State | should -be $null
  }

  it "should not be listening on port 443" {
    (Get-NetTCPConnection -LocalPort 443 -ErrorAction SilentlyContinue).State | should -be $null
  }
}

