

Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    $excludedRules | % { Write-Warning "Excluding Rule $_" }

    Write-Output "Running PsScriptAnalyzer against ./OctopusDSC/DSCResources"
    $results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude $excludedRules
    $results | Out-File PsScriptAnalyzer.log

    Write-Output "Running PsScriptAnalyzer against ./OctopusDSC/Tests"
    $results += Invoke-ScriptAnalyzer ./OctopusDSC/Tests -recurse -exclude $excludedRules
    $results | Out-File PsScriptAnalyzer.log -Append

    # PsScriptAnalyzer tests dont seem to work so well on mac - https://github.com/PowerShell/PowerShell/issues/5707
    if (($null -eq $IsMacOS) -or ($IsMacOS -eq $false)) {
        Write-Output "Running PsScriptAnalyzer against ./OctopusDSC/Examples"
        $results += Invoke-ScriptAnalyzer ./OctopusDSC/Examples -recurse -exclude $excludedRules
        $results | Out-File PsScriptAnalyzer.log -Append
    } else {
        Write-Output "Skipping running PsScriptAnalyzer on `./OctopusDSC/Examples` as it doesn't run well on macOS."
    }
    Write-Output ($results | ConvertTo-Json)
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