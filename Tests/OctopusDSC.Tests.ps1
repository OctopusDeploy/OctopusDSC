Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )

    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/DSCResources" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        Write-Output "Running PsScriptAnalyzer against $path"
        $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules)
        $results | ConvertTo-Json | Out-File PsScriptAnalyzer-DSCResources.log

        $results.length | Should Be 0
    }

    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/Tests" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/Tests"
        Write-Output "Running PsScriptAnalyzer against $path"
        $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules)
        $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Tests.log

        $results.length | Should Be 0
    }

    $existingPSModulePath = $env:PSModulePath
    $path = Resolve-Path "$PSCommandPath/../../"
    if ($isLinux -or $IsMacOS) {
        $newPath = "$($env:PSModulePath);$path"
    } else {
        $newPath = "$($env:PSModulePath);$path"
    }
    Write-host "Setting `$env:PSModulePath to '$newPath'"
    $env:PSModulePath = $newPath

    $excludedRules += 'PSAvoidUsingConvertToSecureStringWithPlainText'

    It "Should have zero PSScriptAnalyzer issues in Scenarios" {
        $path = Resolve-Path "$PSCommandPath/../../Tests/Scenarios"
        Write-Output "Running PsScriptAnalyzer against $path"
        $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules)
        $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Scenarios.log

        $results.length | Should Be 0
    }

    It "Should have zero PSScriptAnalyzer issues in Examples" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/Examples"
        Write-Output "Running PsScriptAnalyzer against $path"
        $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules)
        $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Examples.log

        $results.length | Should Be 0
    }

    $env:PSModulePath = $existingPSModulePath
}

Describe "OctopusDSC.psd1" {
    It "Should be valid" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        $modules = Get-ChildItem $path -Directory
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC"
        Import-LocalizedData -BaseDirectory $path -FileName OctopusDSC.psd1 -BindingVariable Data

        $expected = ($Data.DscResourcesToExport | Sort-Object) -join ","
        $actual = (($modules.Name | Sort-Object) -join ",")
        $actual | should be $expected
    }
}

Describe "Mandatory Parameters" {
    $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
    $schemaMofFiles = Get-ChildItem $path -Recurse -Filter *.mof
    foreach ($schemaMofFile in $schemaMofFiles) {
        $schemaMofFileContent = Get-Content $schemaMofFile.FullName
        $moduleFile = Get-Item ($schemaMofFile.FullName -replace ".schema.mof", ".psm1")

        function Get-ParameterFromFunction($functionName, $ast, $propertyName) {
            $filter = { $true }
            $result = $ast.FindAll($filter, $true);

            $foundMatchingParameter = $false
            foreach($param in $result) {
                if ($null -ne $param.name -and $param.Name.ToString() -eq "`$$propertyName") {
                    $function = $param.Parent.Parent.Parent
                    if ($function -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                        $funcName = ([System.Management.Automation.Language.FunctionDefinitionAst]$function).Name
                        if ($funcName -eq $functionName) {
                            return $param.Attributes.Extent.Text
                        }
                    }
                }
            }
        }

        function Test-Parameter($functionName, $ast, $propertyName, $moduleFile, $propertyType) {
            $param = Get-ParameterFromFunction -functionName $functionName -ast $ast -propertyName $propertyName
            It "Parameter '$propertyName' in function '$functionName' should be marked with [Parameter(Mandatory)] in $($moduleFile.Name) as its a $propertyType property" {
                $param -contains "[Parameter(Mandatory)]" | should be $true
            }
        }

        Describe "Module $($moduleFile.Name)" {
            $tokens = $null;
            $parseErrors = $null;
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($moduleFile.FullName, [ref] $tokens, [ref] $parseErrors);

            It "The module $($moduleFile.Name) should have no parse errors" {
                $parseErrors | should be $null
            }

            foreach($line in $schemaMofFileContent) {
                if ($line -match "\s*(\[\b(Required|Key)\b.*\])\s*(.*) (.*);") {
                    $propertyType = $matches[2]
                    $propertyName = $matches[4].Replace("[]", "");

                    $filter = { $true }
                    $result = $ast.FindAll($filter, $true);

                    $foundMatchingParameter = $false

                    Test-Parameter -functionName "Get-TargetResource" -ast $ast -propertyName $propertyName -moduleFile $moduleFile -propertyType $propertyType
                    Test-Parameter -functionName "Set-TargetResource" -ast $ast -propertyName $propertyName -moduleFile $moduleFile -propertyType $propertyType
                    Test-Parameter -functionName "Test-TargetResource" -ast $ast -propertyName $propertyName -moduleFile $moduleFile -propertyType $propertyType
                }
            }
        }
    }
}

Describe "Test/Get/Set-TargetResource all implement the same properties" {
    $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
    $schemaMofFiles = Get-ChildItem $path -Recurse -Filter *.schema.mof
    foreach ($schemaMofFile in $schemaMofFiles) {
        $schemaMofFileContent = Get-Content $schemaMofFile.FullName
        $moduleFile = Get-Item ($schemaMofFile.FullName -replace ".schema.mof", ".psm1")

        function Get-ParameterFromFunction($functionName, $ast, $propertyName) {
            $filter = { $true }
            $result = $ast.FindAll($filter, $true);

            $foundMatchingParameter = $false
            foreach($param in $result) {
                if ($null -ne $param.name -and $param.Name.ToString() -eq "`$$propertyName") {
                    $function = $param.Parent.Parent.Parent
                    if ($function -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                        $funcName = ([System.Management.Automation.Language.FunctionDefinitionAst]$function).Name
                        if ($funcName -eq $functionName) {
                            return $param
                        }
                    }
                }
            }
        }

        function Test-Parameter($functionName, $ast, $propertyName, $moduleFile, $propertyType) {
            $param = Get-ParameterFromFunction -functionName $functionName -ast $ast -propertyName $propertyName
            It "Function '$functionName' should have parameter '$propertyName' in $($moduleFile.Name) as its a defined in the .schema.mof file" {
                $param | should not be $null
            }
        }

        Describe "Module $($moduleFile.Name)" {
            $tokens = $null;
            $parseErrors = $null;
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($moduleFile.FullName, [ref] $tokens, [ref] $parseErrors);

            It "The module $($moduleFile.Name) should have no parse errors" {
                $parseErrors | should be $null
            }

            foreach($line in $schemaMofFileContent) {
                if ($line -match "\s*(\[.*\])\s*(.*) (.*);") {
                    $propertyType = $matches[1]
                    $propertyName = $matches[3].Replace("[]", "");

                    $filter = { $true }
                    $result = $ast.FindAll($filter, $true);

                    $foundMatchingParameter = $false

                    Test-Parameter -functionName "Get-TargetResource" -ast $ast -propertyName $propertyName -moduleFile $moduleFile -propertyType $propertyType
                    Test-Parameter -functionName "Set-TargetResource" -ast $ast -propertyName $propertyName -moduleFile $moduleFile -propertyType $propertyType
                    Test-Parameter -functionName "Test-TargetResource" -ast $ast -propertyName $propertyName -moduleFile $moduleFile -propertyType $propertyType
                }
            }
        }
    }
}

Describe "Configuration Scenarios" {
    $path = Resolve-Path "$PSCommandPath/../../Tests/Scenarios"
    $configurationFiles = Get-ChildItem $path -Recurse -Filter *.ps1
    foreach ($configurationFile in $configurationFiles) {
        $confName = [System.Io.Path]::GetFileNameWithoutExtension($configurationFile.Name)

        It "Configuration block in scenario $($configurationFile.Name) should have the same name as the file" {
            $configurationFile.FullName | Should -FileContentMatch "Configuration $confName"
        }

        It "Scenario $($configurationFile.Name) should have a matching spec" {
            $specName = $configurationFile.Name.Replace('.ps1', '_spec.rb').ToLower()
            (Resolve-Path "$PSCommandPath/../../Tests/Spec/$specName") | Should -Exist
        }
    }
}
