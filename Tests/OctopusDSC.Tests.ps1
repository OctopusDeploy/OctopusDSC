

Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    $excludedRules | % { Write-Warning "Excluding Rule $_" }
    $results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude $excludedRules
    $results | Out-File PsScriptAnalyzer.log 
    Write-Host ($results | ConvertTo-Json)
    It "Should have zero PSScriptAnalyzer issues" {
        $results.length | Should Be 0
    }
}

Describe "Scenarios are valid" {
    
}