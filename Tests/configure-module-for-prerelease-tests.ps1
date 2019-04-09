param($version)

# check if the version exists in the octopus-testing bucket
$resp = Invoke-WebRequest "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.$version-x64.msi" -Method HEAD -verbose -UseBasicParsing

if($resp.statuscode -ne 200)
{
    Write-Output "Could not find the requested pre-release version ($version) in the octopus-testing bucket"
    EXIT 1
}

# Replace out the $DownloadUrl parameter default in the OctopusDSC module psm1 file
Write-Output "Running pre-release version tests"

$ModulePath = Get-Module -ListAvailable OctopusDSC | Select-Object -expand Path
$infile = Get-Content $ModulePath

$outfile = $infile -replace "[string]$DownloadUrl = `"https://octopus.com/downloads/latest/WindowsX64/OctopusServer`",",
                            "[string]$DownloadUrl = `"https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.$version-x64.msi`","

$outfile | Out-File $ModulePath

Write-Output "Module modified to use $version as 'latest'"

Write-Output "Looking for CurrentState files in $pwd/OctopusDSC/Tests/OctopusServerExeInvocationFiles/"
$currentstatefiles = Get-ChildItem -recurse "OctopusDSC/Tests/OctopusServerExeInvocationFiles/" -filter CurrentState.ps1

$currentstatefiles | ForEach-Object {
    Write-Version "Modifying CurrentState file ${$_.FullName} to use $version as latest"

    $infile = Get-Content $_.FullName

    $outfile = $infile -replace "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
    "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.$version-x64.msi"

    $outfile | Out-File $_.FullName
}
