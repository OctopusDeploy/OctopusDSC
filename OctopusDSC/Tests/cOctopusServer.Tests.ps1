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

        Describe '*-TargetResource Functions' {
            BeforeEach {
                $desiredConfiguration = @{
                     Name                   = 'Stub'
                     Ensure                 = 'Present'
                     State                  = 'Started'
                     WebListenPrefix        = "http://localhost:80"
                     SqlDbConnectionString  = "conn-string"
                     OctopusAdminUsername   = "Admin"
                     OctopusAdminPassword   = "Password"
                }
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