

Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    $excludedRules | % { Write-Warning "Excluding Rule $_" }
    $results = Invoke-ScriptAnalyzer ./OctopusDSC -recurse -exclude $excludedRules
    $results | Out-File PsScriptAnalyzer.log
    Write-Host ($results | ConvertTo-Json)
    It "Should have zero PSScriptAnalyzer issues" {
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