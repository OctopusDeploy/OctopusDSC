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

        Describe 'cOctopusServer' {
            BeforeEach {
                # password is "S3cur3P4ssphraseHere!", loaded from an AES encrypted file
                $pass = ConvertTo-SecureString -string (Get-Content .\OctopusDSC\Tests\Password.txt) -key (Get-Content .\OctopusDSC\Tests\AESKey.key)
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
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
                $mockConfig = [pscustomobject] @{
                    OctopusStorageExternalDatabaseConnectionString         = 'StubConnectionString'
                    OctopusWebPortalListenPrefixes                         = "https://octopus.example.com,http://localhost"
                }
            }

            Mock Import-ServerConfig { return $mockConfig }

            Context 'Get-TargetResource' {
                Mock Get-ItemProperty { return @{ InstallLocation = "c:\Octopus\Octopus" }}
                Mock Get-Service { return @{ Status = "Running" }}

                It 'Returns the proper data' {
                    $config = Get-TargetResource @desiredConfiguration

                    $config.GetType()                  | Should Be ([hashtable])
                    $config['Name']                    | Should Be 'Stub'
                    $config['Ensure']                  | Should Be 'Present'
                    $config['State']                   | Should Be 'Started'
                }
            }

            Context 'Test-TargetResource' {
                $response = @{ Ensure="Absent"; State="Stopped" }
                Mock Get-TargetResource { return $response }

                It 'Returns True when Ensure is set to Absent and Instance does not exist' {
                    $desiredConfiguration['Ensure'] = 'Absent'
                    $desiredConfiguration['State'] = 'Stopped'
                    $response['Ensure'] = 'Absent'
                    $response['State'] = 'Stopped'

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

               It 'Returns True when Ensure is set to Present and Instance exists' {
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
                    Mock Get-RegistryValue { return "" }
                    { Set-TargetResource @desiredConfiguration } | Should throw "Octopus Server requires .NET 4.5.1. Please install it before attempting to install Octopus Server."
                }

                It 'Throws an exception if .net 4.5.1 or above is not installed (only .net 4.5.0 installed)' {
                    Mock Get-RegistryValue { return "378389" }
                    { Set-TargetResource @desiredConfiguration } | Should throw "Octopus Server requires .NET 4.5.1. Please install it before attempting to install Octopus Server."
                }
            }

            Context "Running HA" {
                $executedcommands = @()
                $invocation = 0
                Mock Invoke-OctopusServerCommand {
                    param($parameters)
                    $executedCommands += [pscustomobject]@{ invocation = ++$invocation; params = $parameters } 
                }
                $response = @{ Ensure="Absent"; State="Stopped" }
                Mock Get-TargetResource { return $response }
                Mock Get-RegistryValue { return "478389" }
                Mock Install-MSI {}
                Mock Update-InstallState {}
                Mock Test-OctopusDeployServerResponding { return $true }

                $pass = ConvertTo-SecureString -string (Get-Content .\OctopusDSC\Tests\Password.txt) -key (Get-Content .\OctopusDSC\Tests\AESKey.key)
                $cred = New-Object System.Management.Automation.PSCredential ("Admin", $pass)

                $MasterKey = "Nc91+1kfZszMpe7DMne8wg=="
                $SecureMasterKey = ConvertTo-SecureString $MasterKey -AsPlainText -Force
                $MasterKeyCred = New-Object System.Management.Automation.PSCredential  ("notused", $SecureMasterKey)

                $haparams = @{
                    Ensure = "Present";
                    State = "Started";        
                    Name = "HANode";
                    WebListenPrefix = "http://localhost:82";
                    SqlDbConnectionString = "Server=(local);Database=Octopus;Trusted_Connection=True;";
                    OctopusMasterKey = $MasterKeyCred;
                    OctopusAdminCredential = $cred;
                    ListenPort = 10935;
                    AllowCollectionOfAnonymousUsageStatistics = $false;
                    HomeDirectory = "C:\ChezOctopusSecondNode";
                }

                Set-TargetResource @haparams 

                Write-Host $executedcommands


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