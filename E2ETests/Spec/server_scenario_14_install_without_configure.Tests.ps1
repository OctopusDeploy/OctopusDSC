describe server_scenario_14_install_without_configure {

    # from previous install
    it "should have created c:/Octopus" {
        Test-Path 'c:/Octopus' -PathType Container | should -be $true
    }

    it "should have created C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
        Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Leaf | should -be $true
    }

    it "should have created instance registry entry" {
        Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
    }

    it "should have set the InstallLocation" {
        (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
    }

    it "should have removed C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config" {
        Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' | should -be $false
    }

    it "should have removed OctopusDeploy" {
        Get-Service 'OctopusDeploy' -ErrorAction SilentlyContinue | should -be $null
    }

    it "should be able to get dsc configuration" {
        $ProgressPreference = "SilentlyContinue"
        $state = ""
        do {
            $state = (Get-DscLocalConfigurationManager).LCMState
            write-verbose "LCM state is $state"
            Start-Sleep -Seconds 2
        } while ($state -ne "Idle")

        Get-DSCConfiguration -ErrorAction Stop
    }

    it "should get true back from Test-DSCConfiguraiton" {
        $ProgressPreference = "SilentlyContinue"
        $state = ""
        do {
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

