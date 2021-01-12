#requires -Version 4.0
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')] # these are tests, not anything that needs to be secure
param()

$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf
$modulePath = Split-Path $PSCommandPath -Parent
$modulePath = Resolve-Path "$PSCommandPath/../../DSCResources/$moduleName/$moduleName.psm1"
$module = $null
$octopusServerApplicationId = "{E2096A4C-2391-4BE1-9F17-E353F930E7F1}"
$certificateThumbprint = "dfcbdb879e5315e05982c05793e57c39241797e3"

try
{
    $prefix = [guid]::NewGuid().Guid -replace '-'
    $module = Import-Module $modulePath -Prefix $prefix -PassThru -ErrorAction Stop

    InModuleScope $module.Name {
        $sampleConfigPath = Split-Path $PSCommandPath -Parent
        $sampleConfigPath = Join-Path $sampleConfigPath "SampleConfigs"

        Describe 'cOctopusServerSslCertificate' {
            Context 'Get-TargetResource - when present and port not specified' {
                It 'Returns present and 443 when SSL binding exists' {
                    Mock Get-CurrentSSLBinding {
                        return [PSCustomObject]@{
                            IPPort = "0.0.0.0:443"
                            CertificateHash = $certificateThumbprint
                            AppID = $octopusServerApplicationId
                            CertStore = "My"
                        }
                    }

                    $result = Get-TargetResource -InstanceName "OctopusServer" `
                                                 -Ensure "Present" `
                                                 -Thumbprint $certificateThumbprint `
                                                 -StoreName "My"

                    $result.Ensure | Should -Be 'Present'
                    $result.Port | Should -Be "443"
                    $result.AppID | Should -Be $octopusServerApplicationId
                    $result.CertStore | Should -Be "My"
                    $result.CertificateHash | Should -Be $certificateThumbprint
                }
            }

            Context 'Get-TargetResource - when present and port specified' {
                It 'Returns present and 1443 when SSL binding exists' {
                    Mock Get-CurrentSSLBinding {
                        return [PSCustomObject]@{
                            IPPort = "0.0.0.0:1443"
                            CertificateHash = $certificateThumbprint
                            AppID = $octopusServerApplicationId
                            CertStore = "My"
                        }
                    }

                    $result = Get-TargetResource -InstanceName "OctopusServer" `
                                                 -Ensure "Present" `
                                                 -Thumbprint $certificateThumbprint `
                                                 -StoreName "My" `
                                                 -Port "1443"

                    $result.Ensure | Should -Be 'Present'
                    $result.Port | Should -Be "1443"
                    $result.AppID | Should -Be $octopusServerApplicationId
                    $result.CertStore | Should -Be "My"
                    $result.CertificateHash | Should -Be $certificateThumbprint
                }
            }

            Context 'Get-TargetResource - when absent' {
                It 'Returns absent when binding does not exist' {
                    Mock Get-CurrentSSLBinding {
                        return $null
                    }

                    $result = Get-TargetResource -InstanceName "OctopusServer" `
                                                 -Ensure "Present" `
                                                 -Thumbprint $certificateThumbprint `
                                                 -StoreName "My"

                    $result.Ensure | Should -Be "Absent"
                    $result.CertStore | Should -Be $null
                    $result.CertificateHash | Should -Be $null
                    $result.Port | Should -Be $null
                    $result.AppID | Should -Be $null
                }
            }

            Context 'Test-TargetResource - when present' {
                It 'Returns false when port differs' {
                    Mock Get-CurrentSSLBinding {
                        return [PSCustomObject]@{
                            IPPort = "0.0.0.0:443"
                            CertificateHash = $certificateThumbprint
                            AppID = $octopusServerApplicationId
                            CertStore = "My"
                        }

                        $result = Test-TargetResource -InstanceName "OctopusServer" `
                                                    -Ensure "Present" `
                                                    -Thumbprint $certificateThumbprint `
                                                    -StoreName "My" `
                                                    -Port "1443"

                        $result | Should -Be $false
                    }
                }

                It 'Returns true when port matches' {
                    return [PSCustomObject]@{
                        IPPort = "0.0.0.0:443"
                        CertificateHash = $certificateThumbprint
                        AppID = $octopusServerApplicationId
                        CertStore = "My"
                    }

                    $result = Test-TargetResource -InstanceName "OctopusServer" `
                                                -Ensure "Present" `
                                                -Thumbprint $certificateThumbprint `
                                                -StoreName "My" `
                                                -Port "443"

                    $result | Should -Be $true
                }
            }
        }
    }
}
finally
{
    if ($module)
    {
        Remove-Module -ModuleInfo $module
    }
}