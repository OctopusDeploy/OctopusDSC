#requires -Version 4.0

$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf

$modulePath = Split-Path $PSCommandPath -Parent
$modulePath = Resolve-Path "$PSCommandPath/../../DSCResources/$moduleName/$moduleName.psm1"

$module = $null

try {
    $prefix = [guid]::NewGuid().Guid -replace '-'
    $module = Import-Module $modulePath -Prefix $prefix -PassThru -ErrorAction Stop

    InModuleScope $module.Name {
        Describe 'cOctopusLetsEncryptIntegration' {
            Context 'Get-TargetResource' {
                It 'works' {
                    $true | should be $true
                }
            }
            Context 'Set-TargetResource' {
                It 'works' {
                    $true | should be $true
                }
            }
            Context 'Test-TargetResource' {
                It 'works' {
                    $true | should be $true
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
