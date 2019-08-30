#requires -Version 4.0
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')] # these are tests, not anything that needs to be secure
param()

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

        Describe 'cOctopusServerSpace' {
            BeforeEach {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
                $password = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
                $creds = New-Object System.Management.Automation.PSCredential ("username", $password)

                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
                $desiredConfiguration = @{
                     Url                = 'https://octopus.example.com'
                     Ensure             = 'Present'
                     Name               = 'Integration Team'
                     Description        = 'The integration team space'
                     OctopusCredentials = $creds
                }
            }

            Context 'Get-TargetResource - error scenarios' {
                It 'Throws when both OctopusCredentials and OctopusApiKey are provided' {
                    {Get-TargetResource -Url 'https://octopus.example.com' `
                                                 -Ensure 'Present' `
                                                 -Name 'Integration Team' `
                                                 -OctopusCredentials $creds `
                                                 -OctopusApiKey $creds } | should throw "Please provide either 'OctopusCredentials' or 'OctopusApiKey', not both."
                }

                It 'Throws when neither OctopusCredentials and OctopusApiKey are provided' {
                    {Get-TargetResource -Url 'https://octopus.example.com' `
                                                 -Ensure 'Present' `
                                                 -Name 'Integration Team'} | should throw "Please provide either 'OctopusCredentials' or 'OctopusApiKey'."
                }
            }

            Context 'Get-TargetResource - when present' {
                It 'Returns present when space exists' {
                    Mock Get-Space { return [PSCustomObject]@{ Name = 'Integration Team', Description = 'The integration team space' } }
                    $result = Get-TargetResource -Url 'https://octopus.example.com' `
                                                 -Ensure 'Present' `
                                                 -Name 'Integration Team' `
                                                 -Description 'The integration team space' `
                                                 -OctopusCredentials $creds
                    $result.Ensure | should be 'Present'
                }
            }

            Context 'Get-TargetResource - when absent' {
                It 'Returns absent when space does not exist' {
                    Mock Get-Space { return $null }
                    $result = Get-TargetResource -Url 'https://octopus.example.com' `
                                                 -Ensure 'Present' `
                                                 -Name 'Integration Team' `
                                                 -Description 'The integration team space' `
                                                 -OctopusCredentials $creds
                    $result.Ensure | should be 'Absent'
                }
            }

            Context 'Test-TargetResource' {
                $response = @{  }
                Mock Get-TargetResource { return $response }

                It 'Returns false if space does not exist' {
                    $password = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                    $creds = New-Object System.Management.Automation.PSCredential ("username", $password)

                    $desiredConfiguration['Url'] = 'https://octopus.example.com'
                    $desiredConfiguration['Ensure'] = 'Present'
                    $desiredConfiguration['Name'] = 'Integration Team'
                    $desiredConfiguration['Description'] = 'The integration team space'
                    $desiredConfiguration['OctopusCredentials'] = $creds

                    $response['Url'] = 'https://octopus.example.com'
                    $response['Ensure'] = 'Present'
                    $response['Name'] = $null
                    $response['Description'] = $null
                    $response['OctopusCredentials'] = $creds

                    Test-TargetResource @desiredConfiguration | Should Be $false
                }

                It 'Returns true if space does exist' {
                    $password = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                    $creds = New-Object System.Management.Automation.PSCredential ("username", $password)

                    $desiredConfiguration['Url'] = 'https://octopus.example.com'
                    $desiredConfiguration['Ensure'] = 'Present'
                    $desiredConfiguration['Name'] = 'Integration Team'
                    $desiredConfiguration['Description'] = 'The integration team space'
                    $desiredConfiguration['OctopusCredentials'] = $creds

                    $response['Url'] = 'https://octopus.example.com'
                    $response['Ensure'] = 'Present'
                    $response['Name'] = 'Integration Team'
                    $response['Description'] = 'The integration team space'
                    $response['OctopusCredentials'] = $creds

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

                It 'Returns false if description is different' {
                    $password = ConvertTo-SecureString "1a2b3c4d5e6f" -AsPlainText -Force
                    $creds = New-Object System.Management.Automation.PSCredential ("username", $password)

                    $desiredConfiguration['Url'] = 'https://octopus.example.com'
                    $desiredConfiguration['Ensure'] = 'Present'
                    $desiredConfiguration['Name'] = 'Integration Team'
                    $desiredConfiguration['Description'] = 'The integration team space'
                    $desiredConfiguration['OctopusCredentials'] = $creds

                    $response['Url'] = 'https://octopus.example.com'
                    $response['Ensure'] = 'Present'
                    $response['Name'] = 'Integration Team'
                    $response['Description'] = 'wrong description'
                    $response['OctopusCredentials'] = $creds

                    Test-TargetResource @desiredConfiguration | Should Be $false
                }

                It 'Calls Get-TargetResource (and therefore inherits its checks)' {
                    Test-TargetResource @desiredConfiguration
                    Assert-MockCalled Get-TargetResource
                }
            }

            Context 'Set-TargetResource - when present' {
                It 'Calls Remove-Space if present and ensure set to absent' {
                    Mock Get-Space { return [PSCustomObject]@{ Name = 'Integration Team' } }
                    Mock New-Space
                    Mock Remove-Space
                    $desiredConfiguration['Ensure'] = 'Absent'
                    Set-TargetResource @desiredConfiguration
                    Assert-MockCalled Remove-Space -Exactly 1
                }
            }

            Context 'Set-TargetResource - when absent' {
                It 'Calls New-Space if not present and ensure set to present' {
                    Mock Get-Space { return $null }
                    Mock New-Space
                    Mock Remove-Space
                    Set-TargetResource @desiredConfiguration
                    Assert-MockCalled New-Space  -Exactly 1
                }
            }

            Context 'Set-TargetResource - general' {
                It 'Calls Get-TargetResource (and therefore inherits its checks)' {
                    $response = @{ Url = 'https://octopus.example.com'; Ensure='Present'; Name = 'Integration Team'; Description = 'Desc'; OctopusCredentials = $creds }
                    Mock Get-TargetResource { return $response }
                    Set-TargetResource @desiredConfiguration
                    Assert-MockCalled Get-TargetResource -Exactly 1
                }
            }
        }
    }
}
finally {
    if ($module) {
        Remove-Module -ModuleInfo $module
    }
}