describe server_scenario_06_remove_custom_instance {

  #we deliberately dont cleanup the octopus directory, as it contains logs & config
  it "should have left c:/Octopus alone" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have removed C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | should -be $false
  }

  it "should have removed OctopusDeploy: MyOctopusServer" {
    Get-Service 'OctopusDeploy: MyOctopusServer' -ErrorAction SilentlyContinue | should -be $null
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

  it "should not be listening on port 10943" {
    (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State | should -be $null
  }

  it "should not be listening on port 81" {
    (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State | should -be $null
  }

}

