param(
    [string]$buildVersion,
    [string]$psGalleryApiKey,
    [string]$gitHubApiKey
)
$ErrorActionPreference = 'Stop'

function Publish-ToGitHub($versionNumber, $commitId, $preRelease, $artifact, $gitHubApiKey)
{
    $data = @{
       tag_name = [string]::Format("v{0}", $versionNumber);
       target_commitish = $commitId;
       name = [string]::Format("v{0}", $versionNumber);
       body = '';
       prerelease = $preRelease;
    }

    $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($gitHubApiKey + ":x-oauth-basic"));

    $releaseParams = @{
       Uri = "https://api.github.com/repos/OctopusDeploy/OctopusDSC/releases";
       Method = 'POST';
       Headers = @{ Authorization = $auth; }
       ContentType = 'application/json';
       Body = ($data | ConvertTo-Json -Compress)
    }

    $result = Invoke-RestMethod @releaseParams 
    $uploadUri = $result | Select-Object -ExpandProperty upload_url
    $uploadUri = $uploadUri -creplace '\{\?name,label\}'
    $uploadUri = $uploadUri + "?name=$artifact"

    $params = @{
      Uri = $uploadUri;
      Method = 'POST';
      Headers = @{ Authorization = $auth; }
      ContentType = 'application/zip';
      InFile = $artifact
    }
    Invoke-RestMethod @params
}

try
{
    Write-output "### Updating version number to $buildVersion"
    $content = (Get-Content OctopusDSC/OctopusDSC.psd1)
    $content = $content -replace "ModuleVersion = '[0-9\.]+'", "ModuleVersion = '$buildVersion'"
    Set-Content OctopusDSC/OctopusDSC.psd1 $content

    Write-output "### Import Modules"
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\PackageManagement"
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\PowerShellGet"

    Write-output "### Ensuring nuget.exe is available"
    If (-not (Test-Path "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe")) {
        Write-output "Downloading latest nuget to C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe"
        if (-not (Test-Path "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet")) {
            New-Item -type Directory "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet" | Out-Null
        }
        Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkID=690216&clcid=0x409" -OutFile "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe"
    }

    Write-Output "### Install-PackageProvider nuget -force"
    Install-PackageProvider nuget -force

    Write-output "### Publish-Module -Path 'OctopusDSC'"
    Publish-Module -Path "OctopusDSC" -NuGetApiKey $psGalleryApiKey

    Write-Output "### Publishing to GitHub"

    Compress-Archive -Path .\OctopusDSC -DestinationPath ".\OctopusDSC.$buildVersion.zip"

    $commitId = git rev-parse HEAD
    Publish-ToGitHub -versionNumber $buildVersion `
                     -commitId $commitId `
                     -preRelease $false `
                     -artifact ".\OctopusDSC.$buildVersion.zip" `
                     -gitHubApiKey $gitHubApiKey
}
catch
{
    Write-Output $_
    exit 1
}
