Function Get-ConfigPath
{
    $ConfigPaths = @()

    if( (Test-Path "C:\ProgramData\Octopus\OctopusServer\Instances"))
    {
        $files = Get-ChildItem "C:\ProgramData\Octopus\OctopusServer\Instances" -filter "*.config"

        if($null -ne $files)
        {
            $files | ForEach-Object {
                $Config = Get-Content $_.FullName | ConvertFrom-Json
                write-host "adding '$($Config.ConfigurationFilePath)'"
                $ConfigPaths += $Config.ConfigurationFilePath
            }
        }
    }

    if( (Test-Path "HKLM:\SOFTWARE\Octopus\OctopusServer\"))
    {
        Get-ChildItem  "HKLM:\SOFTWARE\Octopus\OctopusServer\" | ForEach-Object {
            $_ | ForEach-Object {
                write-host "adding '$(Get-ItemProperty $_.PSPath | select -expand Configurationfilepath)'"
                $ConfigPaths += Get-ItemProperty $_.PSPath | select -expand Configurationfilepath
            }
        }
    }

    if( (Test-Path "HKLM:\SOFTWARE\Octopus\Tentacle\" ) )
    {
        Get-ChildItem  "HKLM:\SOFTWARE\Octopus\Tentacle\" | ForEach-Object {
            $_ | ForEach-Object {
                write-host "adding '$(Get-ItemProperty $_.PSPath | select -expand Configurationfilepath)'"
                $ConfigPaths += Get-ItemProperty -Path $_.PSPath | select -expand Configurationfilepath
            }
        }
    }
    return , $ConfigPaths | select -Unique | where-object { $null -ne $_ }
}

Function Get-LogPath
{
    param([string[]]$ConfigPaths)
    $LogPaths = @()
    $ConfigPaths | ForEach-Object {
        $ConfigXML = [xml](Get-Content $_ )
        $Homepath = $ConfigXML.SelectSingleNode('/octopus-settings/set[@key="Octopus.Home"]/text()').Value
        $LogPath = "$Homepath\Logs"
        $LogPaths += $LogPath
    }
    return $LogPaths
}

Write-Host "##teamcity[blockOpened name='Log Files']"

$configPaths = Get-ConfigPath
$configPaths | ForEach-Object {
    $configPath = $_
    Write-Host "##teamcity[blockOpened name='Config File $($configPath)']"
    Get-Content $configPath | Write-Host
    Write-Host "##teamcity[blockClosed name='Config File $($configPath)']"
}

Get-LogPath -ConfigPaths $configPaths | ForEach-Object {
    Get-ChildItem $_ -filter "*.txt" | ForEach-Object {
        $LogPath = $_.FullName
        Write-Host "##teamcity[blockOpened name='Log File $($LogPath)']"
        Get-Content $LogPath | Write-Host
        Write-Host "##teamcity[blockClosed name='Log File $($LogPath)']"
    }
}

Write-Host "##teamcity[blockClosed name='Log Files']"

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
    write-output "-----------------------"
    write-output "ResourcesInDesiredState:"
    write-output "-----------------------"
    $status.ResourcesInDesiredState
    write-output "-----------------------"
    write-output "ResourcesNotInDesiredState:"
    write-output "-----------------------"
    $status.ResourcesNotInDesiredState
} catch { 
    write-output "Get-DSCConfigurationStatus failed"
    write-output $_
}
Write-Host "##teamcity[blockClosed name='Get-DSCConfigurationStatus']"
