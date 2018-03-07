Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    $excludedRules | % { Write-Warning "Excluding Rule $_" }

    $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
    Write-Output "Running PsScriptAnalyzer against $path"
    $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules)
    $results | ConvertTo-Json | Out-File PsScriptAnalyzer-DSCResources.log

    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/DSCResources" {
        $results.length | Should Be 0
    }

    $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/Tests"
    Write-Output "Running PsScriptAnalyzer against $path"
    $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules)
    $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Tests.log

    # it'd be nice to run the PsScriptAnalyzer on `./OctopusDSC/Examples`, but I couldn't get it to detect the DSCModule on mac nor on linux
    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/Tests" {
        $results.length | Should Be 0
    }
}

Describe "OctopusDSC.psd1" {
    It "Should be valid" {
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC/DSCResources"
        $modules = Get-ChildItem $path -Directory
        $path = Resolve-Path "$PSCommandPath/../../OctopusDSC"
        Import-LocalizedData -BaseDirectory $path -FileName OctopusDSC.psd1 -BindingVariable Data

        $expected = ($Data.DscResourcesToExport | Sort-Object) -join ","
        $actual = (($modules | Sort-Object) -join ",")
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
                        $functionName = ([System.Management.Automation.Language.FunctionDefinitionAst]$function).Name
                        if ($functionName -eq $functionName) {
                            return $param.Attributes.Extent.Text
                        }
                    }
                }
            }
        }

        function Test-Parameter($functionName, $ast, $propertyName, $moduleFile, $propertyType) {
            $param = Get-ParameterFromFunction -functionName $functionName -ast $ast -propertyName $propertyName
            It "Parameter '$propertyName' in function '$functionName' should be marked with [Parameter(Mandatory)} in $($moduleFile.Name) as its a $propertyType property" {
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
