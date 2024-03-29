describe tentacle_scenario_02_remove {
    #we deliberately dont cleanup the octopus directory, as it contains logs & config
    it "should have left c:/Octopus alone" {
        Test-Path 'c:/Octopus' -PathType Container | should -be $true
    }

    it "should have left c:/Applications alone" {
        Test-Path 'c:/Applications' -PathType Container | should -be $true
    }

    it "should have removed C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" {
        Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | should -be $false
    }

    describe "ListeningTentacle" {
        it "should have uninstalled the service" {
            Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' -ErrorAction SilentlyContinue | should -be $null
        }

        # Listening Tentacle
        describe "Tentacle: ListeningTentacle" {
            BeforeAll {
                foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                    . $import.fullname
                }

                $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
                $tentacle = Get-TentacleDetails $config.OctopusServerUrl $config.OctopusApiKey "ListeningTentacle"
            }

            it "should not exist" {
                $tentacle.Exists | Should -be $false
            }
        }

        it "should not be listening on port 10933" {
            (Get-NetTCPConnection -LocalPort 10933 -ErrorAction SilentlyContinue).State | should -be $null
        }
    }

    describe "PollingTentacle" {
        # Polling Tentacle
        it "should have uninstalled the service" {
            Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue | should -be $null
        }

        describe "Tentacle: PollingTentacle" {
            BeforeAll {
                foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                    . $import.fullname
                }

                $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
                $tentacle = Get-TentacleDetails $config.OctopusServerUrl $config.OctopusApiKey "PollingTentacle"
            }

            it "should not exist" {
                $tentacle.Exists | Should -be $false
            }
        }
    }

    describe "ListeningTentacleWithoutAutoRegister" {
        # Listening Tentacle with autoregister disabled
        it "should have uninstalled the service" {
            Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' -ErrorAction SilentlyContinue | should -be $null
        }

        describe "Tentacle: ListeningTentacleWithoutAutoRegister" {
            BeforeAll {
                foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                    . $import.fullname
                }

                $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
                $tentacle = Get-TentacleDetails $config.OctopusServerUrl $config.OctopusApiKey "ListeningTentacleWithoutAutoRegister"
            }

            it "should not exist" {
                $tentacle.Exists | Should -be $false
            }
        }
    }

    describe "ListeningTentacleWithThumbprintWithoutAutoRegister" {
        # Listening Tentacle with autoregister disabled but thumbprint set
        it "should have uninstalled the service" {
            Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' -ErrorAction SilentlyContinue | should -be $null
        }

        describe "Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister" {
            BeforeAll {
                foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                    . $import.fullname
                }

                $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
                $tentacle = Get-TentacleDetails $config.OctopusServerUrl $config.OctopusApiKey "ListeningTentacleWithThumbprintWithoutAutoRegister"
            }

            it "should not exist" {
                $tentacle.Exists | Should -be $false
            }
        }
    }

    describe "ListeningTentacleWithCustomAccount" {
        # Listening Tentacle with autoregister disabled but thumbprint set
        it "should have uninstalled the service" {
            Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' -ErrorAction SilentlyContinue | should -be $null
        }

        describe "Tentacle: ListeningTentacleWithCustomAccount" {
            BeforeAll {
                foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                    . $import.fullname
                }

                $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
                $tentacle = Get-TentacleDetails $config.OctopusServerUrl $config.OctopusApiKey "ListeningTentacleWithCustomAccount"
            }

            it "should not exist" {
                $tentacle.Exists | Should -be $false
            }
        }
    }

    describe "WorkerTentacle" {
        # Worker Tentacle
        it "should have uninstalled the service" {
            Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' -ErrorAction SilentlyContinue | should -be $null
        }

        describe "Worker: WorkerTentacle" {
            BeforeAll {
                foreach ($import in @(Get-ChildItem -Path $PSScriptRoot\TestHelpers\*.ps1 -recurse)) {
                    . $import.fullname
                }

                $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
                $worker = Get-WorkerDetails $config.OctopusServerUrl $config.OctopusApiKey "WorkerTentacle"
            }

            it "should not exist" {
                $worker.Exists | Should -be $false
            }
        }
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

    #todo: can we check its been removed from the server somehow?
}

