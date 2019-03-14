$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf
$modulePath = Split-Path $PSCommandPath -Parent
$modulePath = Resolve-Path "$PSCommandPath/../../$moduleName.ps1"

. $modulePath

$samplePath = Split-Path $PSCommandPath -parent
$samplePath = Resolve-path "$samplePath/SampleConfigs/"

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
        Mock Invoke-WebClient -Verifiable

        Mock Get-FileHash { return [pscustomobject]@{Hash =  "abcdef1234567890"} }
        Mock Test-Path { return $true }

        It "Should only request the file hash and not download the file" {
            Request-File 'https://octopus.com/downloads/latest/WindowsX64/OctopusServer' $env:tmp\OctopusServer.msi # -verbose
            Assert-MockCalled "Invoke-WebRequest" -ParameterFilter {$Method -eq "HEAD" } -Times 1
            Assert-MockCalled "Invoke-WebClient" -Times 0
        }
    }

    Context "It should download when hashes mismatch" {
        Mock Invoke-WebRequest {
            param($uri, $saveAs, [switch]$UseBasicParsing, $Method)

            return [pscustomobject]@{
                Headers = @{'x-amz-meta-sha256' = "abcdef1234567891"};
            }
        } -Verifiable
        Mock Invoke-WebClient -Verifiable

        Mock Get-FileHash { return [pscustomobject]@{Hash =  "abcdef1234567890"} }
        Mock Test-Path { return $true }

        It "Should request the file has and also download the file" {
            Request-File 'https://octopus.com/downloads/latest/WindowsX64/OctopusServer' $env:tmp\OctopusServer.msi # -verbose
            Assert-MockCalled "Invoke-WebRequest"  -Times 1
            Assert-MockCalled "Invoke-WebClient" -Times 1
        }
    }
}

Describe "Invoke-OctopusServerCommand" {
    Context "It should not leak password or masterkey" {
        $OctopusServerExePath = "echo"
        Write-Output "Mocked OctopusServerExePath as $OctopusServerExePath"
        Mock Write-Verbose { } -verifiable
        Function Write-CommandOutput {}

        $dbargs = @("database",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200",
            "--masterKey", "ABCD123456ASDBD",
            "--instance", "OctopusServer")
        $pwargs = @("database",
            "--instance", "OctopusServer",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;username=sa;password=p@ssword1234!")
        $pwargs2 = @("database",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;username=sa;pwd=p@ssword1234!",
            "--instance", "OctopusServer")
        $lcargs = @("license",
            "--console",
            "--instance", "OctopusServer",
            "--licenseBase64", "khsandvlinfaslkndsafdvlkjnvdsakljnvasdfkjnsdavkjnvfwq45o3ragoahwer4")
        $npkargs = @("database",
            "--instance", "OctopusServer",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;")

        It "Doesn't try to mask output when no sensitive values exist " {
            Invoke-OctopusServerCommand $npkargs
            Assert-MockCalled Write-Verbose -parameterfilter { $Message -like "*echo database --instance OctopusServer --connectionstring Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;*" } -times 1
        }

        It "Tries to mask the master key" {
            Invoke-OctopusServerCommand $dbargs
            Assert-MockCalled Write-Verbose -parameterfilter { $message -like "*echo database --connectionstring Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200 --masterKey *************** --instance OctopusServer'*"} -times 1  # has at least four asterisks
        }

        It "Tries to mask the Connectionstring password" {
            Invoke-OctopusServerCommand $pwargs
            Assert-MockCalled Write-Verbose -parameterfilter { $Message -like "*echo database --instance OctopusServer --connectionstring Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;username=sa;password=********'*"}  -times 1
        }

        It "Tries to mask the licencebase64" {
            Invoke-OctopusServerCommand $lcargs
            Assert-MockCalled Write-Verbose -parameterfilter { $Message -like "*echo license --console --instance OctopusServer --licenseBase64 *******************************************************************'*"}  -times 1
        }

        It "Should successfully mask the SQL password" {
            ((Get-MaskedOutput $pwargs) -match "p@ssword1234!").Count | Should be 0
        }

        It "Should successfully mask a short-arg SQL password" {
            ((Get-MaskedOutput $pwargs2) -match "p@ssword1234!").Count | Should be 0
        }

        It "Should successfully mask the licence key" {
            $licence = "khsandvlinfaslkndsafdvlkjnvdsakljnvasdfkjnsdavkjnvfwq45o3ragoahwer4"
            ((Get-MaskedOutput $lcargs) -match $licence).Count | Should Be 0
            ((Get-MaskedOutput $lcargs) -match "\*\*\*\*").Count -gt 0 | Should Be $true
        }

        It "Should successfully mask the master key" {
            ((Get-MaskedOutput $dbargs) -match "ABCD123456ASDBD").Count | Should Be 0
            ((Get-MaskedOutput $dbargs) -match "\*\*\*\*").Count -gt 0 | Should Be $true
        }
    }
}

Describe "Test-ValidJson" {
    It "Returns false for known bad json" {
        Test-ValidJson (Get-Content "$SamplePath\octopus.server.exe-output-when-json-has-exception-prepended.json" -raw) | Should Be $false
     }

    It "returns true for known good json" {
        Test-ValidJson (Get-Content "$SamplePath\octopus.server.exe-output-clean.json" -raw) | Should Be $true
    }
}

Describe "Get-CleanedJson" {
    It "Correctly cleans our expected exception-prepended output" {
        $clean = Get-CleanedJson (Get-Content "$SamplePath\octopus.server.exe-output-when-json-has-exception-prepended.json" -raw)
        Test-ValidJson $clean | Should Be $true
        $clean -eq (Get-Content "$SamplePath\octopus.server.exe-output-clean.json" -raw) | Should Be $true
    }
}
