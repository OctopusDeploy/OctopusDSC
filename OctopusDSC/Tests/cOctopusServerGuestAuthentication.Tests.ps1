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

        Describe 'cOctopusServerGuestAuthentication' {
            BeforeEach {
                $desiredConfiguration = @{
                     InstanceName           = 'OctopusServer'
                     Enabled                = $true
                }
            }

            Context 'Get-TargetResource' {
                It 'Returns the proper data' {
                    Mock Test-Path { return $true } -ParameterFilter { $LiteralPath -eq "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe" }
                    Mock Test-OctopusVersionSupportsAuthenticationProvider { return $true }
                    Mock Get-Configuration { return  @{Octopus = @{ WebPortal = @{ GuestLoginEnabled = $true }}} }

                    $config = Get-TargetResource @desiredConfiguration
                    $config.InstanceName            | Should Be 'OctopusServer'
                    $config.Enabled                 | Should Be $true
                }

                It 'Throws an exception if Octopus is not installed' {
                    Mock Test-Path { return $false } -ParameterFilter { $LiteralPath -eq "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe" }
                    Mock Test-OctopusVersionSupportsAuthenticationProvider { return $true }
                    { Get-TargetResource @desiredConfiguration } | Should Throw "Unable to find Octopus (checked for existence of file '$octopusServerExePath')."
                }

                It 'Throws an exception if its an old version of Octopus' {
                    Mock Test-Path { return $true } -ParameterFilter { $LiteralPath -eq "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe" }
                    Mock Test-OctopusVersionSupportsAuthenticationProvider { return $false }
                    { Get-TargetResource @desiredConfiguration } | Should Throw "This resource only supports Octopus Deploy 3.5.0+."
                }
            }

            Context 'Test-TargetResource' {
                $response = @{ InstanceName="OctopusServer"; Enabled=$true }
                Mock Get-TargetResource { return $response }

                It 'Returns True when its currently enabled' {
                    $desiredConfiguration['InstanceName'] = 'OctopusServer'
                    $desiredConfiguration['Enabled'] = $true
                    $response['InstanceName'] = 'OctopusServer'
                    $response['Enabled'] = $true

                    Test-TargetResource @desiredConfiguration | Should Be $true
                }

               It 'Returns false when its currently disabled' {
                    $desiredConfiguration['InstanceName'] = 'OctopusServer'
                    $desiredConfiguration['Enabled'] = $true
                    $response['InstanceName'] = 'OctopusServer'
                    $response['Enabled'] = $false

                    Test-TargetResource @desiredConfiguration | Should Be $false
                }

                It 'Calls Get-TargetResource (and therefore inherits its checks)' {
                    Test-TargetResource @desiredConfiguration
                    Assert-MockCalled Get-TargetResource
                }
            }

            Context 'Set-TargetResource' {
                It 'Calls Invoke-OctopusServerCommand with the correct arguments' {
                    Mock Invoke-OctopusServerCommand

                    Set-TargetResource -InstanceName 'SuperOctopus' -Enabled $false
                    Assert-MockCalled Invoke-OctopusServerCommand -ParameterFilter { ($arguments -join ' ') -eq 'configure --console --instance SuperOctopus --guestLoginEnabled false'}
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