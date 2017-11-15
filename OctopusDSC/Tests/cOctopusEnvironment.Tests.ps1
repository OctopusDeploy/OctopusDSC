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
        $sampleConfigPath = Split-Path $PSCommandPath -Parent
        $sampleConfigPath = Join-Path $sampleConfigPath "SampleConfigs"

        Describe 'cOctopusEnvironment' {
            BeforeEach {
                $password = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                $creds = New-Object System.Management.Automation.PSCredential ("username", $password)

                $desiredConfiguration = @{
                     Url                = 'https://octopus.example.com'
                     Ensure             = 'Present'
                     EnvironmentName    = 'Production'
                     OctopusCredentials = $creds
                }
            }

            Context 'Get-TargetResource' {
                It 'Returns present when environment exists' {
                    Mock Get-Environment { return [PSCustomObject]@{ Name = 'Production' } } -Scope It
                    $result = Get-TargetResource -Url 'https://octopus.example.com' `
                                                 -Ensure 'Present' `
                                                 -EnvironmentName 'Production' `
                                                 -OctopusCredentials $creds
                    $result.Ensure | should be 'Present'
                }

                It 'Returns absent when environment does not exist' {
                    Mock Get-Environment { return $null } -Scope It
                    $result = Get-TargetResource -Url 'https://octopus.example.com' `
                                                 -Ensure 'Present' `
                                                 -EnvironmentName 'Production' `
                                                 -OctopusCredentials $creds
                    $result.Ensure | should be 'Absent'
                }
            }

            Context 'Test-TargetResource' {
                $response = @{  }
                Mock Get-TargetResource { return $response } -Scope It

                It 'Returns false if environment does not exist' {
                    $desiredPassword = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                    $apiKey = New-Object System.Management.Automation.PSCredential ("username", $desiredPassword)

                    $desiredConfiguration['Url'] = 'https://octopus.example.com'
                    $desiredConfiguration['Ensure'] = 'Present'
                    $desiredConfiguration['EnvironmentName'] = 'Production'
                    $desiredConfiguration['OctopusCredentials'] = $apiKey

                    $response['Url'] = 'https://octopus.example.com'
                    $response['Ensure'] = 'Present'
                    $response['EnvironmentName'] = $null
                    $response['OctopusCredentials'] = $apiKey

                    Test-TargetResource @desiredConfiguration | Should Be $false
                }

                It 'Returns true if environment does exist' {
                    $desiredPassword = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                    $apiKey = New-Object System.Management.Automation.PSCredential ("username", $desiredPassword)

                    $desiredConfiguration['Url'] = 'https://octopus.example.com'
                    $desiredConfiguration['Ensure'] = 'Present'
                    $desiredConfiguration['EnvironmentName'] = 'Production'
                    $desiredConfiguration['OctopusCredentials'] = $apiKey

                    $response['Url'] = 'https://octopus.example.com'
                    $response['Ensure'] = 'Present'
                    $response['EnvironmentName'] = 'Production'
                    $response['OctopusCredentials'] = $apiKey

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

                It 'Calls Get-TargetResource (and therefore inherits its checks)' {
                    Test-TargetResource @desiredConfiguration
                    Assert-MockCalled Get-TargetResource
                }
            }

            Context 'Set-TargetResource' {

                It 'Calls New-Environment if not present and ensure set to present' {
                    Mock Get-Environment { return $null } -Scope It
                    Mock New-Environment -Scope It
                    Mock Remove-Environment -Scope It
                    Set-TargetResource @desiredConfiguration
                    Assert-MockCalled New-Environment  -Exactly 1
                }

                It 'Calls Remove-Environment if present and ensure set to absent' {
                    Mock Get-Environment { return [PSCustomObject]@{ Name = 'Production' } } -Scope It
                    Mock New-Environment -Scope It
                    Mock Remove-Environment -Scope It
                    $desiredConfiguration['Ensure'] = 'Absent'
                    Set-TargetResource @desiredConfiguration
                    Assert-MockCalled Remove-Environment -Exactly 1
                }

                It 'Calls Get-TargetResource (and therefore inherits its checks)' {
                    $response = @{ Url = 'https://octopus.example.com'; Ensure='Present'; EnvironmentName = 'Production'; OctopusCredentials = $creds }
                    Mock Get-TargetResource { return $response } -Scope It
                    Set-TargetResource @desiredConfiguration
                    Assert-MockCalled Get-TargetResource -Exactly 1
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