#requires -Version 4.0
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')] # these are tests, not anything that needs to be secure
param()

$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf
$modulePath = Resolve-Path "$PSCommandPath/../../DSCResources/$moduleName/$moduleName.psm1"
$module = $null

try
{
    $prefix = [guid]::NewGuid().Guid -replace '-'

    $module = Import-Module $modulePath -Prefix $prefix -PassThru -ErrorAction Stop

    InModuleScope $module.Name {

        # Get-Service is not available on mac/unix systems - fake it
        $getServiceCommand = Get-Command "Get-Service" -ErrorAction SilentlyContinue
        if ($null -eq $getServiceCommand) {
            function Get-Service {}
        }

        Describe 'cOctopusServer' {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
            $mockConfig = [pscustomobject] @{
                OctopusStorageExternalDatabaseConnectionString         = 'StubConnectionString'
                OctopusWebPortalListenPrefixes                         = "https://octopus.example.com,http://localhost"
            }
            Mock Import-ServerConfig { return $mockConfig }

            function Get-DesiredConfiguration {
                $pass = ConvertTo-SecureString "S3cur3P4ssphraseHere!" -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential ("Admin", $pass)

                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
                $desiredConfiguration = @{
                     Name                   = 'Stub'
                     Ensure                 = 'Present'
                     State                  = 'Started'
                     WebListenPrefix        = "http://localhost:80"
                     SqlDbConnectionString  = "conn-string"
                     OctopusAdminCredential = $cred
                }
                return $desiredConfiguration
            }

            Context 'Get-TargetResource' {
                Context 'When reg key exists and service exists and service started' {
                    Mock Get-ItemProperty { return @{ InstallLocation = "c:\Octopus\Octopus" }}
                    Mock Get-Service { return @{ Status = "Running" }}
                    $desiredConfiguration = Get-DesiredConfiguration
                    $config = Get-TargetResource @desiredConfiguration

                    It 'Should have Ensure=Present' {
                        $config['Ensure']                  | Should Be 'Present'
                    }
                    It 'Should have State=Started' {
                        $config['State']                   | Should Be 'Started'
                    }
                }

                Context 'When reg key exists and service exists and service stopped' {
                    Mock Get-ItemProperty { return @{ InstallLocation = "c:\Octopus\Octopus" }}
                    Mock Get-Service { return @{ Status = "Stopped" }}
                    $desiredConfiguration = Get-DesiredConfiguration
                    $config = Get-TargetResource @desiredConfiguration

                    It 'Should have Ensure=Present' {
                        $config['Ensure']                  | Should Be 'Present'
                    }
                    It 'Should have State=Stopped' {
                        $config['State']                   | Should Be 'Stopped'
                    }
                }

                Context 'When reg key exists and service does not exist' {
                    Mock Get-ItemProperty { return @{ InstallLocation = "c:\Octopus\Octopus" }}
                    Mock Get-Service { return $null }
                    $desiredConfiguration = Get-DesiredConfiguration
                    $config = Get-TargetResource @desiredConfiguration

                    It 'Should have Ensure=Present' {
                        $config['Ensure']                  | Should Be 'Present'
                    }
                    It 'Should have State=Installed' {
                        $config['State']                   | Should Be 'Installed'
                    }
                }

                Context 'When reg key does not exist and service does not exist' {
                    Mock Get-ItemProperty { return $null }
                    Mock Get-Service { return $null }
                    $desiredConfiguration = Get-DesiredConfiguration
                    $config = Get-TargetResource @desiredConfiguration

                    It 'Should have Ensure=Absent' {
                        $config['Ensure']                  | Should Be 'Absent'
                    }
                    It 'Should have State=Stopped' {
                        $config['State']                   | Should Be 'Stopped'
                    }
                }

                Context 'When reg key does not exist and service started' {
                    Mock Get-ItemProperty { return $null }
                    Mock Get-Service { return @{ Status = "Running" } }
                    $desiredConfiguration = Get-DesiredConfiguration
                    $config = Get-TargetResource @desiredConfiguration

                    It 'Should have Ensure=Present' {
                        $config['Ensure']                  | Should Be 'Present'
                    }
                    It 'Should have State=Started' {
                        $config['State']                   | Should Be 'Started'
                    }
                }

                Context 'When reg key does not exist and service stopped' {
                    Mock Get-ItemProperty { return $null }
                    Mock Get-Service { return @{ Status = "Stopped" } }
                    $desiredConfiguration = Get-DesiredConfiguration
                    $config = Get-TargetResource @desiredConfiguration

                    It 'Should have Ensure=Present' {
                        $config['Ensure']                  | Should Be 'Present'
                    }
                    It 'Should have State=Stopped' {
                        $config['State']                   | Should Be 'Stopped'
                    }
                }
            }

            Context "Parameter Validation" {
                Context "Ensure = 'Present' and 'State' = 'Stopped'" {
                    It "Should throw if 'Name' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -DownloadUrl "blah2" } | Should throw "Parameter 'Name' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should throw if 'DownloadUrl' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" } | Should throw "Parameter 'DownloadUrl' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should throw if 'WebListenPrefix' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" } | Should throw "Parameter 'WebListenPrefix' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should throw if 'SqlDbConnectionString' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3"} | Should throw "Parameter 'SqlDbConnectionString' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should not throw if 'OctopusAdminCredential' not supplied but 'OctopusMasterKey' is supplied" {
						$creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null -OctopusMasterKey $creds} | Should not throw
                    }
                    It "Should not throw if 'OctopusAdminCredential' is '[PSCredential]::Empty' but 'OctopusMasterKey' is supplied" {
						$creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusMasterKey $creds} | Should not throw
                    }
					It "Should throw if 'OctopusAdminCredential' not supplied and 'OctopusMasterKey' is not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null -OctopusMasterKey $null} | Should throw "Parameter 'OctopusAdminCredential' must be supplied when 'Ensure' is 'Present' and you have not supplied a master key to use an existing database."
                    }
                    It "Should throw if 'OctopusAdminCredential' is '[PSCredential]::Empty' and 'OctopusMasterKey' is '[PSCredential]::Empty'" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4"} | Should throw "Parameter 'OctopusAdminCredential' must be supplied when 'Ensure' is 'Present' and you have not supplied a master key to use an existing database."
                    }
                    It "Should not throw if all params are supplied" {
                        $creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $creds} | Should not throw
                    }
                }

                Context "Ensure = 'Present' and 'State' = 'Started'" {
                    It "Should throw if 'Name' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Stopped' -DownloadUrl "blah2" } | Should throw "Parameter 'Name' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should throw if 'DownloadUrl' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" } | Should throw "Parameter 'DownloadUrl' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should throw if 'WebListenPrefix' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" } | Should throw "Parameter 'WebListenPrefix' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should throw if 'SqlDbConnectionString' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3"} | Should throw "Parameter 'SqlDbConnectionString' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should not throw if 'OctopusAdminCredential' not supplied but 'OctopusMasterKey' is supplied" {
						$creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null -OctopusMasterKey $creds} | Should not throw
                    }
                    It "Should not throw if 'OctopusAdminCredential' is '[PSCredential]::Empty' but 'OctopusMasterKey' is supplied" {
						$creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusMasterKey $creds} | Should not throw
                    }
					It "Should throw if 'OctopusAdminCredential' not supplied and 'OctopusMasterKey' is not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null -OctopusMasterKey $null} | Should throw "Parameter 'OctopusAdminCredential' must be supplied when 'Ensure' is 'Present' and you have not supplied a master key to use an existing database."
                    }
                    It "Should throw if 'OctopusAdminCredential' is '[PSCredential]::Empty' and 'OctopusMasterKey' is '[PSCredential]::Empty'" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4"} | Should throw "Parameter 'OctopusAdminCredential' must be supplied when 'Ensure' is 'Present' and you have not supplied a master key to use an existing database."
                    }
                    It "Should not throw if all params are supplied" {
                        $creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $creds} | Should not throw
                    }
                }

                Context "Ensure = 'Present' and 'State' = 'Installed'" {
                    It "Should not throw if 'Name' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' -DownloadUrl "blah2" } | Should not throw
                    }
                    It "Should throw if 'DownloadUrl' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' } | Should throw "Parameter 'DownloadUrl' must be supplied when 'Ensure' is 'Present'."
                    }
                    It "Should not throw if 'WebListenPrefix' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' -DownloadUrl "blah2" } | Should not throw
                    }
                    It "Should not throw if 'SqlDbConnectionString' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' -DownloadUrl "blah2" -WebListenPrefix "blah3"} | Should not throw
                    }
                    It "Should not throw if 'OctopusAdminCredential' not supplied" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null} | Should not throw
                    }
                    It "Should not throw if 'OctopusAdminCredential' is '[PSCredential]::Empty'" {
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4"} | Should not throw
                    }
                    It "Should not throw if all params are supplied" {
                        $creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Present' -State 'Installed' -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $creds} | Should not throw
                    }
                }

                Context "Ensure = 'Absent' and 'State' = 'Stopped'" {
                    It "Should throw if 'Name' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' } | Should throw "Parameter 'Name' must be supplied when 'Ensure' is 'Absent'."
                    }
                    It "Should not throw if 'DownloadUrl' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' -Name "blah1" } | Should not throw
                    }
                    It "Should not throw if 'WebListenPrefix' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" } | Should not throw
                    }
                    It "Should not throw if 'SqlDbConnectionString' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3"} | Should not throw
                    }
                    It "Should not throw if 'OctopusAdminCredential' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null} | Should not throw
                    }
                    It "Should not throw if 'OctopusAdminCredential' is '[PSCredential]::Empty'" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4"} | Should not throw
                    }
                    It "Should not throw if all params are supplied" {
                        $creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Absent' -State 'Stopped' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $creds} | Should not throw
                    }
                }

                Context "Ensure = 'Absent' and 'State' = 'Started'" {
                    It "Should throw if 'Name' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' } | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'DownloadUrl' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' -Name "blah1"} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'WebListenPrefix' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' -Name "blah1" -DownloadUrl "blah2" } | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'SqlDbConnectionString' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3"} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'OctopusAdminCredential' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'OctopusAdminCredential' is '[PSCredential]::Empty'" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4"} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if all params are supplied" {
                        $creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Absent' -State 'Started' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $creds} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be running at the same time. You probably want 'State = `"Stopped`"."
                    }
                }

                Context "Ensure = 'Absent' and 'State' = 'Installed'" {
                    It "Should throw if 'Name' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' } | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'DownloadUrl' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' -Name "blah1"} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'WebListenPrefix' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' -Name "blah1" -DownloadUrl "blah2" } | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'SqlDbConnectionString' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3"} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'OctopusAdminCredential' not supplied" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $null} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if 'OctopusAdminCredential' is '[PSCredential]::Empty'" {
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4"} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                    It "Should throw if all params are supplied" {
                        $creds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString))
                        { Test-ParameterSet -Ensure 'Absent' -State 'Installed' -Name "blah1" -DownloadUrl "blah2" -WebListenPrefix "blah3" -SqlDbConnectionString "blah4" -OctopusAdminCredential $creds} | Should throw "Invalid configuration requested. You have asked for the service to not exist, but also be installed at the same time. You probably want 'State = `"Stopped`"."
                    }
                }
            }

            Context 'Test-TargetResource' {
                $response = @{ Ensure="Absent"; State="Stopped" }
                Mock Get-TargetResource { return $response }

                It 'Returns True when Ensure is set to Absent and Instance does not exist' {
                    $desiredConfiguration = Get-DesiredConfiguration
                    $desiredConfiguration['Ensure'] = 'Absent'
                    $desiredConfiguration['State'] = 'Stopped'
                    $response['Ensure'] = 'Absent'
                    $response['State'] = 'Stopped'

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

               It 'Returns True when Ensure is set to Present and Instance exists' {
                $desiredConfiguration = Get-DesiredConfiguration
                    $desiredConfiguration['Ensure'] = 'Present'
                    $desiredConfiguration['State'] = 'Started'
                    $response['Ensure'] = 'Present'
                    $response['State'] = 'Started'

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }
            }

            Context 'Set-TargetResource' {
                #todo: more tests
                It 'Throws an exception if .net 4.5.1 or above is not installed (no .net reg key found)' {
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Get-RegistryValue { return "" }
                    Mock Update-InstallState
                    $desiredConfiguration = Get-DesiredConfiguration
                    { Set-TargetResource @desiredConfiguration } | Should throw "Octopus Server requires .NET 4.5.1. Please install it before attempting to install Octopus Server."
                }

                It 'Throws an exception if .net 4.5.1 or above is not installed (only .net 4.5.0 installed)' {
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Get-RegistryValue { return "378389" }
                    Mock Update-InstallState
                    $desiredConfiguration = Get-DesiredConfiguration
                    { Set-TargetResource @desiredConfiguration } | Should throw "Octopus Server requires .NET 4.5.1. Please install it before attempting to install Octopus Server."
                }
            }

            Context "Octopus server command line" {
                function Get-CurrentConfiguration ([string] $testName) {
                    & (Resolve-Path "$PSCommandPath/../../Tests/OctopusServerExeInvocationFiles/$testName/CurrentState.ps1")
                }

                function Get-RequestedConfiguration ([string] $testName) {
                    & (Resolve-Path "$PSCommandPath/../../Tests/OctopusServerExeInvocationFiles/$testName/RequestedState.ps1")
                }

                function Assert-ExpectedResult ([string] $testName) {
                    # todo: test order of execution here
                    $invocations = & (Resolve-Path "$PSCommandPath/../../Tests/OctopusServerExeInvocationFiles/$testName/ExpectedResult.ps1")
                    it "Should call octopus.server.exe $($invocations.count) times" {
                        Assert-MockCalled -CommandName 'Invoke-OctopusServerCommand' -Times $invocations.Count -Exactly
                    }
                    foreach($line in $invocations) {
                        It "Should call octopus.server.exe with args '$line'" {
                            Assert-MockCalled -CommandName 'Invoke-OctopusServerCommand' -Times 1 -Exactly -ParameterFilter { ($arguments -join ' ') -eq $line }
                        }
                    }
                }

                function Get-TempFolder {
                    if ("$($env:TmpDir)" -ne "") {
                        return $env:TmpDir
                    } else {
                        return $env:Temp
                    }
                }

                Context "New instance" {
                    Mock Invoke-OctopusServerCommand #{write-host $args}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "NewInstance" }
                    Mock Get-RegistryValue { return "478389" } # checking .net 4.5
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Update-InstallState {}
                    Mock Test-OctopusDeployServerResponding { return $true }
                    Mock Test-OctopusVersionNewerThan { return $true } # just assume we're the most recent version
                    Mock ConvertFrom-SecureString { return "" } # mock this, as its not available on mac/linux

                    $params = Get-RequestedConfiguration "NewInstance"
                    Set-TargetResource @params

                    Assert-ExpectedResult "NewInstance"
                    it "Should download the MSI" {
                        Assert-MockCalled Request-File
                        Assert-MockCalled Invoke-MsiExec
                    }
                }

                Context "New instance with metrics" {
                    Mock Invoke-OctopusServerCommand #{write-host $args}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "NewInstanceWithMetrics" }
                    Mock Get-RegistryValue { return "478389" } # checking .net 4.5
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Update-InstallState {}
                    Mock Test-OctopusDeployServerResponding { return $true }
                    Mock Test-OctopusVersionNewerThan { return $true } # just assume we're the most recent version
                    Mock ConvertFrom-SecureString { return "" } # mock this, as its not available on mac/linux

                    $params = Get-RequestedConfiguration "NewInstanceWithMetrics"
                    Set-TargetResource @params

                    Assert-ExpectedResult "NewInstanceWithMetrics"
                    it "Should download the MSI" {
                        Assert-MockCalled Request-File
                        Assert-MockCalled Invoke-MsiExec
                    }
                }

                Context "When MasterKey is supplied on new instance" {
                    Mock Invoke-OctopusServerCommand #{write-host $args}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "MasterKeySupplied" }
                    Mock Get-RegistryValue { return "478389" } # checking .net 4.5
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Update-InstallState {}
                    Mock Test-OctopusDeployServerResponding { return $true }
                    Mock Test-OctopusVersionNewerThan { return $true } # just assume we're the most recent version
                    Mock ConvertFrom-SecureString { return "" } # mock this, as its not available on mac/linux

                    $params = Get-RequestedConfiguration "MasterKeySupplied"

                    Set-TargetResource @params

                    it "Should download the MSI" {
                        Assert-MockCalled Request-File
                        Assert-MockCalled Invoke-MsiExec
                    }
                    Assert-ExpectedResult "MasterKeySupplied"
                }

                Context "When uninstalling running instance" {
                    Mock Invoke-OctopusServerCommand #{ param ($arguments) write-host $arguments}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "UninstallingRunningInstance" }
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Get-ExistingOctopusService { return @() }
                    Mock Get-LogDirectory { return Get-TempFolder }
                    Mock Test-Path -ParameterFilter { $path -eq "$($env:SystemDrive)\Octopus\Octopus-x64.msi" } { return $true }
                    Mock Start-Process { return @{ ExitCode = 0} }

                    $params = Get-RequestedConfiguration "UninstallingRunningInstance"
                    Set-TargetResource @params

                    it "Should not download the MSI" {
                        Assert-MockCalled Request-File -Times 0 -Exactly
                        Assert-MockCalled Invoke-MsiExec -Times 0 -Exactly
                    }
                    it "Should uninstall the MSI" {
                        Assert-MockCalled Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq "msiexec.exe" -and $ArgumentList -eq "/x $($env:SystemDrive)\Octopus\Octopus-x64.msi /quiet /l*v $(Get-TempFolder)\Octopus-x64.msi.uninstall.log"}
                    }
                    Assert-ExpectedResult "UninstallingRunningInstance"
                }

                Context "Run-on-server user - new install" {
                    Mock Invoke-OctopusServerCommand #{ param ($arguments) write-host $arguments}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "NewInstallWithBuiltInWorker" }
                    Mock Get-RegistryValue { return "478389" } # checking .net 4.5
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Update-InstallState {}
                    Mock Test-OctopusDeployServerResponding { return $true }
                    Mock Test-OctopusVersionNewerThan { return $true }
                    Mock ConvertFrom-SecureString { return "" } # mock this, as its not available on mac/linux

                    $params = Get-RequestedConfiguration "NewInstallWithBuiltInWorker"
                    Set-TargetResource @params

                    it "Should download the MSI" {
                        Assert-MockCalled Request-File
                        Assert-MockCalled Invoke-MsiExec
                    }
                    Assert-ExpectedResult "NewInstallWithBuiltInWorker"
                }

                Context "Run-on-server user - existing install" {
                    Mock Invoke-OctopusServerCommand #{ param ($arguments) write-host $arguments}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "EnableBuiltInWorkerOnExistingInstance" }
                    Mock Get-RegistryValue { return "478389" } # checking .net 4.5
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Update-InstallState {}
                    Mock Test-OctopusDeployServerResponding { return $true }
                    Mock Test-OctopusVersionNewerThan { return $true }
                    Mock ConvertFrom-SecureString { return "" } # mock this, as its not available on mac/linux

                    $params = Get-RequestedConfiguration "EnableBuiltInWorkerOnExistingInstance"
                    Set-TargetResource @params

                    it "Should not download the MSI" {
                        Assert-MockCalled Request-File -Times 0 -Exactly
                        Assert-MockCalled Invoke-MsiExec -Times 0 -Exactly
                    }
                    Assert-ExpectedResult "EnableBuiltInWorkerOnExistingInstance"
                }

                Context "Upgrade" {
                    Mock Invoke-OctopusServerCommand #{ param ($arguments) write-host $arguments}
                    Mock Get-TargetResource { return Get-CurrentConfiguration "UpgradeExistingInstance" }
                    Mock Get-RegistryValue { return "478389" } # checking .net 4.5
                    Mock Invoke-MsiExec {}
                    Mock Get-LogDirectory {}
                    Mock Request-File {}
                    Mock Update-InstallState {}
                    Mock Test-OctopusDeployServerResponding { return $true }
                    Mock Test-OctopusVersionNewerThan { return $true }
                    Mock ConvertFrom-SecureString { return "" } # mock this, as its not available on mac/linux

                    $params = Get-RequestedConfiguration "UpgradeExistingInstance"
                    Set-TargetResource @params

                    it "Should download the MSI" {
                        Assert-MockCalled Request-File
                        Assert-MockCalled Invoke-MsiExec
                    }
                    Assert-ExpectedResult "UpgradeExistingInstance"
                }
            }
        }
    }
}
finally
{
    if ($module) {
        Remove-Module -ModuleInfo $module
    }
}