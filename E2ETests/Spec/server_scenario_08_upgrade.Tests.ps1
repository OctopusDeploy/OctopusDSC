describe server_scenario_08_upgrade {

    it "should have created c:/Octopus" {
        Test-Path 'c:/Octopus' -PathType Container | should -be $true
    }

    it "should have installed the binary" {
        Test-Path 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe' | should -be $true
    }

    it "should have installed a newer version" {
        # we should've upgraded past this
        (Get-Item 'C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe').VersionInfo.FileVersion | should -BeGreaterThan [System.Version]::Parse('3.3.24.0')
    }

    it "should have created registry entries" {
        Test-Path 'HKLM:\Software\Octopus\OctopusServer' | should -be $true
    }

    it "should have set the InstallLocation" {
        (Get-ItemProperty -Path 'HKLM:\Software\Octopus\OctopusServer' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Octopus\"
    }

    it "should have created the config file" {
        Test-Path 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -PathType Leaf | should -be $true
    }

    it "should have set 'ConfigurationFilePath' in the config file" {
        $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -raw
        $contents | should -match '"ConfigurationFilePath": "C:\\\\Octopus\\\\OctopusServer-OctopusServer.config"'
    }

    it "should have set 'Name' in the config file" {
        $contents = Get-Content 'C:/ProgramData/Octopus/OctopusServer/Instances/OctopusServer.config' -raw
        $contents | should -match '"Name": "OctopusServer"'
    }

    it "should have created the service" {
        Get-Service 'OctopusDeploy' | should -not -be $null
    }

    it "should have set the service to running" {
        (Get-Service 'OctopusDeploy').Status | should -be "Running"
    }

    it "should have set the service start mode" {
        (Get-Service 'OctopusDeploy').StartType | should -be 'Automatic'
    }

    it "should have set the service runas user" {
        (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy'").StartName | should -be 'LocalSystem'
    }

    it "should be listening on port 10943" {
        (Get-NetTCPConnection -LocalPort 10943 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
    }

    it "should be listening on port 81" {
        (Get-NetTCPConnection -LocalPort 81 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
    }

    describe "Environment: UAT 1" {
        BeforeAll {
            foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                . $import.fullname
            }

            $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
            $environment = Get-EnvironmentDetails $config.OctopusServerUrl $config.OctopusApiKey "UAT 1"
        }

        it "should not exist" {
            $environment.Exists | Should -be $false
        }
    }

    #dsc overall status
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

