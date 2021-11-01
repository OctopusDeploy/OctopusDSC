describe server_scenario_05_install_custom_instance {

    it "should have created c:/Octopus" {
        Test-Path 'c:/Octopus' -PathType Container | should -be $true
    }

    it "should have created C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe" {
        Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' -PathType Leaf | should -be $true
    }

    it "should have created registry entries" {
        Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
    }

    it "should have set the InstallLocation" {
        (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
    }

    it "should have created the config file" {
        Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' -PathType Leaf | should -be $true
    }

    it "should have set 'ConfigurationFilePath' in the config file" {
        $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' -raw
        $contents | should -match '"ConfigurationFilePath": "C:\\\\Octopus\\\\OctopusServer-MyOctopusServer.config"'
    }

    it "should have set 'Name' in the config file" {
        $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/MyOctopusServer.config' -raw
        $contents | should -match '"Name": "MyOctopusServer"'
    }

    it "should have created the service" {
        Get-Service 'OctopusDeploy: MyOctopusServer' | should -not -be $null
    }

    it "should have set the service to running" {
        (Get-Service 'OctopusDeploy: MyOctopusServer').Status | should -be "Running"
    }

    it "should have set the service start mode" {
        (Get-Service 'OctopusDeploy: MyOctopusServer').StartType | should -be 'Automatic'
    }

    it "should have set the service runas user" {
        (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy: MyOctopusServer'").StartName | should -be 'LocalSystem'
    }

    it "should be listening on port 10943" {
        (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
    }

    it "should be listening on port 81" {
        (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
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

