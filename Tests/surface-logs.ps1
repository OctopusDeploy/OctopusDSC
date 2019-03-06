Function Get-ConfigPath
{
    $files = Get-ChildItem "C:\ProgramData\Octopus\OctopusServer\Instances" -filter "*.config"

    $ConfigPaths = @()

    if($null -ne $files)
    {
        $files | ForEach-Object {
            $Config = Get-Content $_.FullName | ConvertFrom-Json
            $ConfigPaths += $Config.ConfigurationFilePath
        }
    }

    if( (Test-Path "HKLM:\SOFTWARE\Octopus\OctopusServer\"))
    {
        Get-ChildItem  "HKLM:\SOFTWARE\Octopus\OctopusServer\" | ForEach-Object {
            $_ | ForEach-Object {
                $ConfigPaths += Get-ItemProperty $_.PSPath | select -expand Configurationfilepath
            }
        }
    }

    if( (Test-Path "HKLM:\SOFTWARE\Octopus\Tentacle\" ) )
    {
        Get-ChildItem  "HKLM:\SOFTWARE\Octopus\Tentacle\" | ForEach-Object {
            $_ | ForEach-Object {
                $ConfigPaths += Get-ItemProperty -Path $_.PSPath | select -expand Configurationfilepath
            }
        }
    }
    return $ConfigPaths | select -Unique
}

Function Get-LogPath
{
    param([string[]]$ConfigPaths)
    $LogPaths = @()
    $ConfigPaths| ForEach-Object {
        $ConfigXML = [xml](Get-Content $_ )
        $Homepath = $ConfigXML.SelectSingleNode('/octopus-settings/set[@key="Octopus.Home"]/text()').Value
        $LogPath = "$Homepath\Logs"
        $LogPaths += $LogPath
    }
    return $LogPaths
}

Write-Host "##teamcity[blockOpened name='Log Files']"

Get-LogPath -ConfigPaths (Get-ConfigPath) | ForEach-Object {
    Get-ChildItem $_ -filter "*.txt" | ForEach-Object {
        $LogPath = $_.FullName
        Write-Host "##teamcity[blockOpened name='Log File $($LogPath)']"
        Get-Content $LogPath | Write-Host
        Write-Host "##teamcity[blockClosed name='Log File $($LogPath)']"
    }
}

Write-Host "##teamcity[blockClosed name='Log Files']"
