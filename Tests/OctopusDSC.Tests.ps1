Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    $excludedRules | % { Write-Warning "Excluding Rule $_" }

    Write-Output "Running PsScriptAnalyzer against ./OctopusDSC/DSCResources"
    $results = @(Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude $excludedRules)
    $results | ConvertTo-Json | Out-File PsScriptAnalyzer-DSCResources.log

    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/DSCResources" {
        $results.length | Should Be 0
    }

    Write-Output "Running PsScriptAnalyzer against ./OctopusDSC/Tests"
    $results = @(Invoke-ScriptAnalyzer ./OctopusDSC/Tests -recurse -exclude $excludedRules)
    $results | ConvertTo-Json | Out-File PsScriptAnalyzer-Tests.log

    # it'd be nice to run the PsScriptAnalyzer on `./OctopusDSC/Examples`, but I couldn't get it to detect the DSCModule on mac nor on linux
    It "Should have zero PSScriptAnalyzer issues in OctopusDSC/Tests" {
        $results.length | Should Be 0
    }
}

Describe "OctopusDSC.psd1" {
    It "Should be valid" {
        $modules = Get-ChildItem ./OctopusDSC/DSCResources -Directory
        Import-LocalizedData -BaseDirectory ./OctopusDSC -FileName OctopusDSC.psd1 -BindingVariable Data

        $expected = ($Data.DscResourcesToExport | Sort-Object) -join ","
        $actual = (($modules | Sort-Object) -join ",")
        $actual | should be $expected
    }
}

Describe "Mandatory Parameters" {
    It "All required or key properties in the mof file should be marked with [Parameter(Mandatory)} in the psm1 file" {
        $schemaMofFiles = Get-ChildItem ./OctopusDSC/DSCResources -Recurse -Filter *.mof
        foreach ($schemaMofFile in $schemaMofFiles) {
            $schemaMofFileContent = Get-Content $schemaMofFile.FullName
            $moduleFile = Get-Item ($schemaMofFile.FullName -replace ".schema.mof", ".psm1")

            $tokens = $null;
            $parseErrors = $null;
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($moduleFile.FullName, [ref] $tokens, [ref] $parseErrors);

            $parseErrors | should be $null

            foreach($line in $schemaMofFileContent) {
                if ($line -match "\s*(\[.*?(Required|Key).*\])\s*(.*) (.*);") {
                    $propertyName = $matches[4];

                    $filter = {
                        ($args[0] -is [System.Management.Automation.Language.ParameterAst]) -and
                        ($args[0].Name -eq $propertyName)
                    }
                    $result = $ast.FindAll($filter, $true);

                    foreach($param in $result) {
                        $function = $param.Parent.Parent.Parent
                        if ($function -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                            $functionName = ([System.Management.Automation.Language.FunctionDefinitionAst]$function).Name
                            if (($functionName -like "Get-TargetResource") -or
                                ($functionName -like "Set-TargetResource") -or
                                ($functionName -like "Test-TargetResource")) {

                                $parameterAttributes = $param.Attributes.Extent.Text
                                if ($parameterAttributes -notcontains "[Parameter(Mandatory)]") {
                                    $filename = $moduleFile.Name -replace $moduleFile.Extension, ''
                                    throw "$filename.$functionName.$($param.Name) should be marked as mandatory, as they are marked as required/key in the mof file"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

Describe "Configuration Scenarios" {
    $configurationFiles = Get-ChildItem ./Tests/Scenarios -Recurse -Filter *.ps1
    foreach ($configurationFile in $configurationFiles) {
        $confName = [System.Io.Path]::GetFileNameWithoutExtension($configurationFile.Name)

        It "Configuration block in scenario $($configurationFile.Name) should have the same name as the file" {
            $configurationFile.FullName | Should -FileContentMatch "Configuration $confName"
        }
    }
}
