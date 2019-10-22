Write-Host "##teamcity[blockOpened name='LCM Configuration']"
Get-DscLocalConfigurationManager
Write-Host "##teamcity[blockClosed name='LCM Configuration']"

$ProgressPreference = "SilentlyContinue"

Write-Host "##teamcity[blockOpened name='Get-DSCConfigurationStatus']"
try { 
    $status = Get-DSCConfigurationStatus
    write-output "Get-DSCConfigurationStatus succeeded"
    write-output "-----------------------"
    write-output "DSCConfigurationStatus:"
    write-output "-----------------------"
    $status | format-list | write-output
    write-output "------------------------"
    write-output "ResourcesInDesiredState:"
    write-output "------------------------"
    if ($status.ResourcesInDesiredState.length -eq 0) {
        write-output "No resources in desired state"
        write-output "---------------------------"
    } else {
        $status.ResourcesInDesiredState | foreach-object {
            $_ | write-output
            write-output "------------------------"
        }
    }
    write-output "---------------------------"
    write-output "ResourcesNotInDesiredState:"
    write-output "---------------------------"
    if ($status.ResourcesNotInDesiredState.length -eq 0) {
        write-output "No resources not in desired state"
        write-output "---------------------------"
    } else {
        $status.ResourcesNotInDesiredState | foreach-object {
            $_ | write-output
            write-output "---------------------------"
        }
    }
} catch { 
    write-output "Get-DSCConfigurationStatus failed"
    write-output $_
}
Write-Host "##teamcity[blockClosed name='Get-DSCConfigurationStatus']"
