#requires -Version 4.0

$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf
$modulePath = Split-Path $PSCommandPath -Parent
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

        Describe 'cTentacleAgent' {
            BeforeEach {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
                $desiredConfiguration = @{
                     Name                   = 'Stub'
                     Ensure                 = 'Present'
                     State                  = 'Started'
                }
            }

            Context 'Test-ParameterSet' {
                It 'Throws if PublicHostNameConfiguration is Custom but CustomPublicHostName not set' {
                    { Test-ParameterSet -publicHostNameConfiguration "Custom" -CustomPublicHostName $null -WorkerPools @() -Environments @('My Env') -Roles @() -Tenants @() -TenantTags @()} | Should Throw "Invalid configuration requested"
                }
                It 'Throws if WorkerPools are provided and Environments are provided' {
                    { Test-ParameterSet -publicHostNameConfiguration "PublicIp" -CustomPublicHostName $null -WorkerPools @('My Worker Pool') -Environments @('My Env') -Roles @() -Tenants @() -TenantTags @() } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if WorkerPools are provided and Roles are provided' {
                    { Test-ParameterSet -publicHostNameConfiguration "PublicIp" -CustomPublicHostName $null -WorkerPools @('My Worker Pool') -Environments @() -Roles @('My Roles') -Tenants @() -TenantTags @() } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if WorkerPools are provided and Tenants are provided' {
                    { Test-ParameterSet -publicHostNameConfiguration "PublicIp" -CustomPublicHostName $null -WorkerPools @('My Worker Pool') -Environments @() -Roles @() -Tenants @('Jim-Bob') -TenantTags @() } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if WorkerPools are provided and Tenant Tags are provided' {
                    { Test-ParameterSet -publicHostNameConfiguration "PublicIp" -CustomPublicHostName $null -WorkerPools @('My Worker Pool') -Environments @() -Roles @() -Tenants @() -TenantTags @('CustomerType/VIP') } | Should Throw "Invalid configuration requested"
                }
            }

            Context 'Confirm-RegistrationParameter' {
                It 'Throws if RegisterWithServer is false but environment provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Environments @('My Env') } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if RegisterWithServer is false but roles provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Roles @('app-server') } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if RegisterWithServer is false but tenants provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Tenants @('Jim-Bob') } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if RegisterWithServer is false but tenant Tags provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -TenantTags @('CustomerType/VIP', 'Hosting/OnPrem') } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if RegisterWithServer is false but policy provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Policy "my policy" } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if RegisterWithServer is true but no OctopusServerUrl provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $true -OctopusServerUrl $null } | Should Throw "Invalid configuration requested"
                }
                It 'Throws if RegisterWithServer is true but no ApiKey provided' {
                    { Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $true -OctopusServerUrl "https://example.octopus.com" -ApiKey $null } | Should Throw "Invalid configuration requested"
                }
                It 'Does not throw if RegisterWithServer is false and environment provided as empty string' {
                    Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Environments ""
                }
                It 'Does not throw if RegisterWithServer is false and environment provided as empty array' {
                    Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Environments @()
                }
                It 'Does not throw if RegisterWithServer is false and environment provided as array with empty element' {
                    Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False -Environments @('')
                }
                It 'Does not throw if RegisterWithServer is false and no environment provided' {
                    Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $False
                }
                It 'Does not throw if RegisterWithServer is true and OctopusServerUrl and ApiKey     provided' {
                    Confirm-RegistrationParameter -Ensure "Present" -RegisterWithServer $true -OctopusServerUrl "https://example.octopus.com" -ApiKey "API-1234"
                }
                It 'Throws if Ensure = absent, RegisterWithServer is true and no ApiKey provided' {
                    { Confirm-RegistrationParameter -Ensure "Absent" -RegisterWithServer $true -OctopusServerUrl "https://example.octopus.com" -ApiKey $null } | Should Throw "Invalid configuration requested"
                }
            }

            Context 'Confirm-RequestedState' {
                It 'Throws if Ensure is absent but state is started' {
                    { Confirm-RequestedState @{"Ensure" = "Absent"; "State" = "Started";} } | Should Throw "Invalid configuration requested"
                }
                It 'Does not throws if Ensure is absent but state not provided' {
                    { Confirm-RequestedState @{"Ensure" = "Absent";} } | Should Not Throw
                }
            }

            Context 'Get-TargetResource' {
                Mock Get-ItemProperty { return @{ InstallLocation = "c:\Octopus\Tentacle\Stub" }}
                Mock Get-Service { return @{ Status = "Running" }}

                It 'Returns the proper data' {
                    $config = Get-TargetResource -Name 'Stub' -PublicHostNameConfiguration "PublicIp"

                    $config.GetType()                  | Should Be ([hashtable])
                    $config['Name']                    | Should Be 'Stub'
                    $config['Ensure']                  | Should Be 'Present'
                    $config['State']                   | Should Be 'Started'
                }

                It "Throws if we specify a null or invalid CustomHostName" {
                    { Get-TargetResource -Name "Stub" -PublicHostNameConfiguration "Custom" -CustomPublicHostName $null } | Should Throw "invalid or null"
                    { Get-TargetResource -Name "Stub" -PublicHostNameConfiguration "Custom" -CustomPublicHostName "  " } | Should Throw "invalid or null"
                    { Get-TargetResource -Name "Stub" -PublicHostNameConfiguration "Custom" -CustomPublicHostName "mydnsname" } | Should Not Throw
                }
            }

            Context 'Test-TargetResource' {
                $response = @{ Ensure="Absent"; State="Stopped" }
                Mock Get-TargetResource { return $response }

                It 'Returns True when Ensure is set to Absent and Tentacle does not exist' {
                    $desiredConfiguration['Ensure'] = 'Absent'
                    $desiredConfiguration['State'] = 'Stopped'
                    $response['Ensure'] = 'Absent'
                    $response['State'] = 'Stopped'

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

               It 'Returns True when Ensure is set to Present and Tentacle exists' {
                    $desiredConfiguration = @{
                        Ensure = 'Present'
                        State = 'Started'
                        OctopusServerUrl = 'http://fakeserver1'
                        APIKey = 'API-GRKUQFCFIJM7G2RJM3VMRW43SK'
                        Name = 'Tentacle1'
                        Environments = @()
                        Roles = @()
                        WorkerPools = @()
                        Space = "Default"
                    }
                    $response['Ensure'] = 'Present'
                    $response['State'] = 'Started'

                    # Declare mock objects
                    $mockMachine = @{
                        Name = "MockMachine"
                        EnvironmentIds = @()
                        WorkerPools = @()
                        Roles = @()
                    }

                    # Declare mock calls
                    Mock Get-MachineFromOctopusServer {return $mockMachine}
                    Mock Get-APIResult {return [string]::Empty}
                    Mock Get-TentacleThumbprint { return "ABCDE123456" }
                    Mock Get-Space { return @{
                        "Id" = "Spaces-1"
                    }}
                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

                It 'Throws an error when space does not exist' {
                    $desiredConfiguration = @{
                        Ensure = 'Present'
                        State = 'Started'
                        OctopusServerUrl = 'http://fakeserver1'
                        APIKey = 'API-GRKUQFCFIJM7G2RJM3VMRW43SK'
                        Name = 'Tentacle1'
                        Environments = @()
                        Roles = @()
                        WorkerPools = @()
                        Space = "NonExistentSpace"
                    }
                    $response['Ensure'] = 'Present'
                    $response['State'] = 'Started'

                    # Declare mock objects
                    $mockMachine = @{
                        Name = "MockMachine"
                        EnvironmentIds = @()
                        WorkerPools = @()
                        Roles = @()
                    }

                    # Declare mock calls
                    Mock Get-MachineFromOctopusServer {return $mockMachine}
                    Mock Get-APIResult {return [string]::Empty}
                    Mock Get-TentacleThumbprint { return "ABCDE123456" }
                    Mock Get-Space { return $null}
                    { Test-TargetResource @desiredConfiguration } | Should -Throw -ExpectedMessage "Unable to find a space by the name of"
                }

                It 'Returns true when space exists' {
                    $desiredConfiguration = @{
                        Ensure = 'Present'
                        State = 'Started'
                        OctopusServerUrl = 'http://fakeserver1'
                        APIKey = 'API-GRKUQFCFIJM7G2RJM3VMRW43SK'
                        Name = 'Tentacle1'
                        Environments = @()
                        Roles = @()
                        WorkerPools = @()
                        Space = "Default"
                    }
                    $response['Ensure'] = 'Present'
                    $response['State'] = 'Started'

                    # Declare mock objects
                    $mockMachine = @{
                        Name = "MockMachine"
                        EnvironmentIds = @()
                        WorkerPools = @()
                        Roles = @()
                    }

                    # Declare mock calls
                    Mock Get-MachineFromOctopusServer {return $mockMachine}
                    Mock Get-APIResult {return [string]::Empty}
                    Mock Get-TentacleThumbprint { return "ABCDE123456" }
                    Mock Get-Space { return "Spaces-1"}
                    { Test-TargetResource @desiredConfiguration } | Should Be $true
                }
            }

            Context 'Set-TargetResource' {
                #todo: more tests
                Mock Invoke-AndAssert { return $true }
                Mock Install-Tentacle { return $true }
            }
        }

        Describe "Testing Get-MyPublicIPAddress" {
            $testIP = "54.121.34.56"
            Mock Invoke-RestMethod { return $testIP }

            Context "First option works" {
                It "Should return an IPv4 address" {
                    Get-MyPublicIPAddress | Should Be $testIP
                }
            }

            Context "First option is down" {
                Mock Invoke-RestMethod { throw } -ParameterFilter { $uri -eq "https://api.ipify.org/"}
                It "Should return an IPv4 address" {
                    Get-MyPublicIPAddress | Should Be $testIP
                }
            }

            Context "First and Second Options are down" {
                Mock Invoke-RestMethod { throw } -ParameterFilter { $uri -eq "https://api.ipify.org/" -or $uri -eq 'https://canhazip.com/'}
                It "Should return an IPv4 address" {
                    Get-MyPublicIPAddress | Should Be $testIP
                }
            }

            Context "All three are down, should throw" {
                Mock Invoke-RestMethod { throw }
                It "Should throw" {
                    { Get-MyPublicIPAddress } | Should Throw "Unable to determine"
                }
            }

            Context "A service returns an invalid IP" {
                Mock Invoke-RestMethod { return "IAMNOTANIPADDRESS" }
                It "Should Throw" {
                      { Get-MyPublicIpAddress } | Should Throw "couldn't parse"
                }
            }
        }

        Context "Tentacle command line" {
            function Get-CurrentConfiguration ([string] $testName) {
                & (Resolve-Path "$PSCommandPath/../../Tests/TentacleExeInvocationFiles/$testName/CurrentState.ps1")
            }

            function Get-RequestedConfiguration ([string] $testName) {
                & (Resolve-Path "$PSCommandPath/../../Tests/TentacleExeInvocationFiles/$testName/RequestedState.ps1")
            }

            function Assert-ExpectedResult ([string] $testName) {
                # todo: test order of execution here
                $invocations = & (Resolve-Path "$PSCommandPath/../../Tests/TentacleExeInvocationFiles/$testName/ExpectedResult.ps1")
                it "Should call tentacle.exe $($invocations.count) times" {
                    Assert-MockCalled -CommandName 'Invoke-TentacleCommand' -Times $invocations.Count -Exactly
                }
                foreach($line in $invocations) {
                    It "Should call tentacle.exe with args '$line'" {
                        Assert-MockCalled -CommandName 'Invoke-TentacleCommand' -Times 1 -Exactly -ParameterFilter { ($arguments -join ' ') -eq $line }
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

            # create stubs for these cmdlets on linux/mac as they dont natively exist
            # leading to pester complaining that it cant mock it...
            if (-not $isWindows) {
                function Start-Service {}
                function Stop-Service {}
                function Get-CimInstance {}
            }

            Context "New instance" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "NewInstance" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-PublicHostName { return "mytestserver.local"; }
                Mock New-Item {}

                $params = Get-RequestedConfiguration "NewInstance"
                Set-TargetResource @params

                Assert-ExpectedResult "NewInstance"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
            }

            Context "New polling tentacle" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "NewPollingTentacle" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-PublicHostName { return "mytestserver.local"; }
                Mock New-Item {}

                $params = Get-RequestedConfiguration "NewPollingTentacle"
                Set-TargetResource @params

                Assert-ExpectedResult "NewPollingTentacle"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
            }

            Context "New instance in space" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "NewInstanceInSpace" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-PublicHostName { return "mytestserver.local"; }
                Mock New-Item {}

                $params = Get-RequestedConfiguration "NewInstanceInSpace"
                Set-TargetResource @params

                Assert-ExpectedResult "NewInstanceInSpace"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
            }

            Context "New Worker" {
                Mock Invoke-TentacleCommand # { write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "NewWorker" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-PublicHostName { return "mytestserver.local"; }
                Mock New-Item {}
                Mock Test-TentacleExecutableExists { return $true }

                $params = Get-RequestedConfiguration "NewWorker"
                Set-TargetResource @params

                Assert-ExpectedResult "NewWorker"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
            }

            Context "New Worker in space" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "NewWorkerInSpace" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-PublicHostName { return "mytestserver.local"; }
                Mock New-Item {}
                Mock Test-TentacleExecutableExists { return $true }

                $params = Get-RequestedConfiguration "NewWorkerInSpace"
                Set-TargetResource @params

                Assert-ExpectedResult "NewWorkerInSpace"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
            }

            Context "Install only" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "InstallOnly" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock New-Item {}

                $params = Get-RequestedConfiguration "InstallOnly"
                Set-TargetResource @params

                Assert-ExpectedResult "InstallOnly"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start not the service" {
                    Assert-MockCalled Start-Service -times 0
                }
            }

            Context "Uninstall running instance" {
                Mock Invoke-TentacleCommand # { write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "UninstallingRunningInstance" }
                Mock Invoke-MsiExec {}
                Mock Invoke-MsiUninstall {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-CimInstance { return @() } # no other instances on the box
                Mock Test-TentacleExecutableExists { return $true }

                $params = Get-RequestedConfiguration "UninstallingRunningInstance"
                Set-TargetResource @params

                Assert-ExpectedResult "UninstallingRunningInstance"
                it "Should not download the MSI" {
                    Assert-MockCalled Request-File -times 0
                }
                it "Should not install the MSI" {
                    Assert-MockCalled Invoke-MsiExec -times 0
                }
                it "Should uninstall the MSI" {
                    Assert-MockCalled Invoke-MsiUninstall
                }
                it "Should not start the service" {
                    Assert-MockCalled Start-Service -times 0
                }
            }

            Context "Uninstall running instance (with space)" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "UninstallingRunningInstanceInSpace" }
                Mock Invoke-MsiExec {}
                Mock Invoke-MsiUninstall {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Get-CimInstance { return @() } # no other instances on the box
                Mock Test-TentacleExecutableExists { return $true }

                $params = Get-RequestedConfiguration "UninstallingRunningInstanceInSpace"
                Set-TargetResource @params

                Assert-ExpectedResult "UninstallingRunningInstanceInSpace"
                it "Should not download the MSI" {
                    Assert-MockCalled Request-File -times 0
                }
                it "Should not install the MSI" {
                    Assert-MockCalled Invoke-MsiExec -times 0
                }
                it "Should uninstall the MSI" {
                    Assert-MockCalled Invoke-MsiUninstall
                }
                it "Should not start the service" {
                    Assert-MockCalled Start-Service -times 0
                }
            }

            Context "Upgrade existing instance" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "UpgradeExistingInstance" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Stop-Service {}
                Mock New-Item {}

                $params = Get-RequestedConfiguration "UpgradeExistingInstance"
                Set-TargetResource @params

                Assert-ExpectedResult "UpgradeExistingInstance"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
                it "Should stop the service" {
                    Assert-MockCalled Stop-Service
                }
            }

            Context "Upgrade existing instance in space" {
                Mock Invoke-TentacleCommand #{ write-host "`"$($args[1] -join ' ')`"," }
                Mock Get-TargetResource { return Get-CurrentConfiguration "UpgradeExistingInstanceInSpace" }
                Mock Invoke-MsiExec {}
                Mock Request-File {}
                Mock Update-InstallState {}
                Mock Invoke-AndAssert {}
                Mock Start-Service {}
                Mock Stop-Service {}
                Mock New-Item {}

                $params = Get-RequestedConfiguration "UpgradeExistingInstanceInSpace"
                Set-TargetResource @params

                Assert-ExpectedResult "UpgradeExistingInstanceInSpace"
                it "Should download the MSI" {
                    Assert-MockCalled Request-File
                }
                it "Should install the MSI" {
                    Assert-MockCalled Invoke-MsiExec
                }
                it "Should start the service" {
                    Assert-MockCalled Start-Service
                }
                it "Should stop the service" {
                    Assert-MockCalled Stop-Service
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
