$script:scriptRoot = $PSScriptRoot

Describe "PSScriptAnalyzer" {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath "powershell-helpers.ps1")
    }

    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/DSCResources" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        Write-Output "Running PsScriptAnalyzer against $path"
        $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude @(
            'PSUseShouldProcessForStateChangingFunctions'
            'PSReviewUnusedParameter' # too many false positives from https://github.com/PowerShell/PSScriptAnalyzer/issues/1472
            ))
        $results | ConvertTo-Json | Out-File PsScriptAnalyzer-DSCResources.log

        $results.length | Should -Be 0
    }

    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/Tests" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/Tests"
        Write-Output "Running PsScriptAnalyzer against $path"
        $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude @('PSUseShouldProcessForStateChangingFunctions'))
        $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Tests.log

        $results.length | Should -Be 0
    }

    Context "Scenarios" {
        $script:existingPSModulePath = ""
        BeforeAll {
            $script:existingPSModulePath = $env:PSModulePath
            $path = Resolve-Path "$PSCommandPath/../../"
            if ($isLinux -or $IsMacOS) {
                $newPath = "$($env:PSModulePath):$path"
            } else {
                $newPath = "$($env:PSModulePath);$path"
            }
            Write-Output "Setting `$env:PSModulePath to '$newPath'"
            $env:PSModulePath = $newPath
        }
        AfterAll {
            $env:PSModulePath = $script:existingPSModulePath
        }
        It "Should have zero PSScriptAnalyzer issues in Scenarios" {
            $isRunningUnderTeamCity = (Test-Path Env:\TEAMCITY_PROJECT_NAME)
            if ($isRunningUnderTeamCity) {
                #unfortunately, cant get the following tests to run on our CentOS buildagent
                #keep getting:
                # "Undefined DSC resource 'cOctopusServer'. Use Import-DSCResource to import the resource."
                #even though it works fine on ubuntu locally
                Set-ItResult -Inconclusive -Because "We couldnt get this test to run on our CentOS buildagent"
            } else {
                $path = Resolve-Path "$PSCommandPath/../../Tests/Scenarios"
                Write-Output "Running PsScriptAnalyzer against $path"
                $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude @('PSUseShouldProcessForStateChangingFunctions', 'PSAvoidUsingConvertToSecureStringWithPlainText'))
                $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Scenarios.log
                if ($IsLinux -or $IsMacOS) {
                    $results = $results | where-object {
                        # these DSC resources are available on linux
                        ($_.Message -ne "Undefined DSC resource 'LocalConfigurationManager'. Use Import-DSCResource to import the resource.") -and
                        ($_.Message -ne "Undefined DSC resource 'Script'. Use Import-DSCResource to import the resource.") -and
                        ($_.Message -ne "Undefined DSC resource 'User'. Use Import-DSCResource to import the resource.") -and
                        ($_.Message -ne "Undefined DSC resource 'Group'. Use Import-DSCResource to import the resource.") -and
                        # it's getting confused - Group here is actually the DSC resource, not an alias.
                        ($_.Message -ne "'Group' is an alias of 'Group-Object'. Alias can introduce possible problems and make scripts hard to maintain. Please consider changing alias to its full content.")
                    }
                }
                $results.length | Should -Be 0
            }
        }

        It "Should have zero PSScriptAnalyzer issues in Examples" {
            $isRunningUnderTeamCity = (Test-Path Env:\TEAMCITY_PROJECT_NAME)
            if ($isRunningUnderTeamCity) {
                #unfortunately, cant get the following tests to run on our CentOS buildagent
                #keep getting:
                # "Undefined DSC resource 'cOctopusServer'. Use Import-DSCResource to import the resource."
                #even though it works fine on ubuntu locally
                Set-ItResult -Inconclusive -Because "We couldnt get this test to run on our CentOS buildagent"
            } else {
                $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/Examples"
                Write-Output "Running PsScriptAnalyzer against $path"
                $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude @('PSUseShouldProcessForStateChangingFunctions', 'PSAvoidUsingConvertToSecureStringWithPlainText'))
                $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Examples.log

                $results.length | Should -Be 0
            }
        }
    }
}

Describe "OctopusDSC.psd1" {
    It "Should be valid" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        $modules = Get-ChildItem $path -Directory
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC"
        Import-LocalizedData -BaseDirectory $path -FileName OctopusDSC.psd1 -BindingVariable Data

        $expected = ($Data.DscResourcesToExport | Sort-Object) -join ","
        $actual = (($modules.Name | Sort-Object) -join ",")
        $actual | Should -Be $expected
    }
}

Describe "Mandatory Parameters" {
    BeforeAll {
        . (Join-Path -Path $script:scriptRoot -ChildPath "powershell-helpers.ps1")
        $parseErrorTestCases = @()
        $mandatoryParamTestCases = @()
        $nonMandatoryParamTestCases = @()

        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        $schemaMofFiles = Get-ChildItem $path -Recurse -Filter *.mof
        foreach ($schemaMofFile in $schemaMofFiles) {
            $schemaMofFileContent = Get-Content $schemaMofFile.FullName
            $moduleFile = Get-Item ($schemaMofFile.FullName -replace ".schema.mof", ".psm1")
            $tokens = $null;
            $parseErrors = $null;
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($moduleFile.FullName, [ref] $tokens, [ref] $parseErrors);
            $filter = { $true }
            $astMembers = $ast.FindAll($filter, $true);

            $parseErrorTestCases += @{ moduleFileName = $moduleFile.Name; parseErrorCount = $parseErrors.length }

            function Get-TestCase($functionName, $astMembers, $propertyName, $moduleFileName, $propertyType)
            {
                $param = Get-ParameterFromFunction -functionName $functionName -astMembers $astMembers -propertyName $propertyName
                $paramisMandatory = $param -contains "[Parameter(Mandatory)]"
                return @{
                    functionName = $functionName;
                    propertyName = $propertyName;
                    moduleFileName = $moduleFile.Name;
                    propertyType = $propertyType;
                    paramisMandatory = $paramisMandatory
                }
            }

            foreach($line in $schemaMofFileContent) {
                if ($line -match "\s*(\[.*\b(Required|Key)\b.*\])\s*(.*) (.*);") {
                    $propertyType = $matches[2]
                    $propertyName = $matches[4].Replace("[]", "");
                    $mandatoryParamTestCases += Get-TestCase "Get-TargetResource"  $astMembers $propertyName $moduleFile.Name $propertyType
                    $mandatoryParamTestCases += Get-TestCase "Set-TargetResource"  $astMembers $propertyName $moduleFile.Name $propertyType
                    $mandatoryParamTestCases += Get-TestCase "Test-TargetResource"  $astMembers $propertyName $moduleFile.Name $propertyType
                } elseif ($line -match "\s*(\[.*\])\s*(.*) (.*);") {
                    $propertyType = $matches[1]
                    $propertyName = $matches[3].Replace("[]", "");

                    $nonMandatoryParamTestCases += Get-TestCase "Get-TargetResource"  $astMembers $propertyName $moduleFile.Name $propertyType
                    $nonMandatoryParamTestCases += Get-TestCase "Set-TargetResource"  $astMembers $propertyName $moduleFile.Name $propertyType
                    $nonMandatoryParamTestCases += Get-TestCase "Test-TargetResource"  $astMembers $propertyName $moduleFile.Name $propertyType
                }
            }
        }
    }

    It "The module <moduleFileName> should have no parse errors" -TestCases $parseErrorTestCases {
        param($moduleFileName, $parseErrorCount)
        $parseErrorCount | should -be 0
    }

    It "Parameter '<propertyName>' in function '<functionName>' should Be marked with [Parameter(Mandatory)] in <moduleFileName> as its a <propertyType> property" -TestCases $mandatoryParamTestCases {
        param($functionName, $propertyName, $moduleFileName, $propertyType, $paramisMandatory)
        $paramisMandatory | Should -Be $true
    }

    It "Parameter <propertyName> in function <functionName> should not be marked with [Parameter(Mandatory)] in <moduleFileName> as its not mandatory in the mof" -TestCases $nonMandatoryParamTestCases {
        param($functionName, $propertyName, $moduleFileName, $propertyType, $paramisMandatory)
        $paramisMandatory | Should -Be $false
    }
}

Describe "Test/Get/Set-TargetResource all implement the same properties" {
    BeforeAll {
        . (Join-Path -Path $script:scriptRoot -ChildPath "powershell-helpers.ps1")
        function Get-TestCase($functionName, $astMembers, $propertyName, $moduleFileName, $propertyType) {
            $param = Get-ParameterFromFunction -functionName $functionName -astMembers $astMembers -propertyName $propertyName
            $paramExists = $null -ne $param
            return @{
                functionName = $functionName;
                propertyName = $propertyName;
                moduleFileName = $moduleFile.Name;
                paramExists = $paramExists
            }
        }
    
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        $schemaMofFiles = Get-ChildItem $path -Recurse -Filter *.schema.mof
        $cases = @()
        foreach ($schemaMofFile in $schemaMofFiles) {
            $schemaMofFileContent = Get-Content $schemaMofFile.FullName
            $moduleFile = Get-Item ($schemaMofFile.FullName -replace ".schema.mof", ".psm1")
    
            $tokens = $null;
            $parseErrors = $null;
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($moduleFile.FullName, [ref] $tokens, [ref] $parseErrors);
            $filter = { $true }
            $astMembers = $ast.FindAll($filter, $true);
            foreach($line in $schemaMofFileContent) {
                if ($line -match "\s*(\[.*\])\s*(.*) (.*);") {
                    $propertyName = $matches[3].Replace("[]", "");
                    $cases += Get-TestCase "Get-TargetResource" $astMembers $propertyName $moduleFile.Name
                    $cases += Get-TestCase "Set-TargetResource" $astMembers $propertyName $moduleFile.Name
                    $cases += Get-TestCase "Test-TargetResource" $astMembers $propertyName $moduleFile.Name
                }
            }
        }
    }

    It "Function <functionName> should have parameter <propertyName> in <moduleFileName> as its a defined in the .schema.mof file" -TestCases $cases {
        param($functionName, $propertyName, $moduleFileName, $paramExists)
        $paramExists | Should -be $true
    }
}

Describe "Configuration Scenarios" {
    BeforeAll {
        $path = Resolve-Path "$PSCommandPath/../../Tests/Scenarios"
        $name = @{label="name";expression={[System.Io.Path]::GetFileNameWithoutExtension($_.Name)}};
        $fullName = @{label="fullName";expression={$_.FullName}};
        . (Join-Path -Path $script:scriptRoot -ChildPath "powershell-helpers.ps1")

        $cases = @(Get-ChildItem $path -Recurse -Filter *.ps1 | Select-Object -Property $name, $fullName) | ConvertTo-Hashtable
    }

    It "Configuration block in scenario <name> should have the same name as the file" -TestCases $cases {
        param([string]$name, [string]$fullName)
        $fullName | Should -FileContentMatch "Configuration $name"
    }

    It "Scenario <name> should have a matching spec" -TestCases $cases {
        param([string]$name, [string]$fullName)
        $specName = ($name + '_spec.rb').ToLower()
        (Resolve-Path "$PSCommandPath/../../Tests/Spec/$specName") | Should -Exist
    }
}
