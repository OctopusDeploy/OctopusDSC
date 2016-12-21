param(
    [string]$buildVersion,
    [string]$psGalleryApiKey
)

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

    write-host "### Install-PackageProvider nuget -force"
    Install-PackageProvider nuget -force

    Write-output "### Publish-Module -Path 'OctopusDSC'"
    Publish-Module -Path "OctopusDSC" -NuGetApiKey $psGalleryApiKey
}
catch
{
    write-host $_
    exit 1
}
