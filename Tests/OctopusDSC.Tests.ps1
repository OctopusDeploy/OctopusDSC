

Describe "I am the top-level repo test file" {
    It "Is a dummy test" {
        $true | Should Be $true
    }
}

Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions' #, 
        # 'PSUseSingularNouns' # , 
        # 'PSAvoidUsingConvertToSecureStringWithPlainText'
    )
    $excludedRules | % { Write-Warning "Excluding Rule $_" }
    $results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude $excludedRules
    $results | Out-File PsScriptAnalyzer.log 
    Write-Host ($results | ConvertTo-Json)    
    # Write-Output "PSScriptAnalyzer found $($results.length) issues"
    It "Should have zero PSScriptAnalyzer issues" {
        $results.length | Should Be 0
    }
}

Describe "Scenarios are valid" {
    
}