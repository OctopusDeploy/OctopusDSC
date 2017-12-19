$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf
$modulePath = Split-Path $PSCommandPath -Parent
$modulePath = Resolve-Path "$PSCommandPath/../../$moduleName.ps1"

. $modulePath

Describe "Get-ODSCParameter" {
    $desiredConfiguration = @{
        Name                   = 'Stub'
        Ensure                 = 'Present'
    }

    Function Test-GetODSCParameter
    {
        param(
            $Name,
            $Ensure,
            $DefaultValue = 'default'
        )
       return (Get-ODSCParameter $MyInvocation.MyCommand.Parameters)
    }

    It "Should be able to return our known default values" {
        (Test-GetODSCParameter @desiredConfiguration).DefaultValue | Should be 'default'
    }
}

Describe "Request-File" {
    Context "It shouldn't download when hashes match" {
        Mock Invoke-WebRequest {
            param($uri, $saveAs, [switch]$UseBasicParsing, $Method)

            return [pscustomobject]@{
                Headers = @{'x-amz-meta-sha256' = "abcdef1234567890"};
            }
        } -Verifiable

        Mock Get-FileHash { return [pscustomobject]@{Hash =  "abcdef1234567890"} }
        Mock Test-Path { return $true }

        It "Should only call Invoke-WebRequest once" {
            Request-File 'https://octopus.com/downloads/latest/WindowsX64/OctopusServer' $env:tmp\OctopusServer.msi # -verbose
            Assert-MockCalled "Invoke-WebRequest" -ParameterFilter {$Method -eq "HEAD" } -Times 1
        }
    }

    Context "It should download when hashes mismatch" {
        Mock Invoke-WebRequest {
            param($uri, $saveAs, [switch]$UseBasicParsing, $Method)

            return [pscustomobject]@{
                Headers = @{'x-amz-meta-sha256' = "abcdef1234567891"};
            }
        } -Verifiable

        Mock Get-FileHash { return [pscustomobject]@{Hash =  "abcdef1234567890"} }
        Mock Test-Path { return $true }

        It "Should call Invoke-WebRequest at least twice" {
            Request-File 'https://octopus.com/downloads/latest/WindowsX64/OctopusServer' $env:tmp\OctopusServer.msi # -verbose
            Assert-MockCalled "Invoke-WebRequest"  -Times 2
        }
    }
}

