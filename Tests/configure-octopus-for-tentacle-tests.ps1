# If for whatever reason this doesn't work, check this file:
Start-Transcript -path "C:\Octopus\Logs\configure-octopus-for-tentacle-tests.txt" -append

$OFS = "`r`n"
$OctopusURI = "http://localhost:81"
$octopusAdminUsername="OctoAdmin"
$octopusAdminPassword="SuperS3cretPassw0rd!"

try
{
  if (-not (Test-Path "c:\temp\octopus-configured.marker")) {

    Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
    Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

    #connect
    $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
    $repository = new-object Octopus.Client.OctopusRepository $endpoint

    #sign in
    $credentials = New-Object Octopus.Client.Model.LoginCommand
    $credentials.Username = $octopusAdminUsername
    $credentials.Password = $octopusAdminPassword
    $repository.Users.SignIn($credentials)

    #create the api key
    $user = $repository.Users.GetCurrent()
    $createApiKeyResult = $repository.Users.CreateApiKey($user, "Octopus DSC Testing")

    #save it to enviornment variables for tests to use
    [environment]::SetEnvironmentVariable("OctopusServerUrl", $OctopusURI, "User")
    [environment]::SetEnvironmentVariable("OctopusServerUrl", $OctopusURI, "Machine")
    [environment]::SetEnvironmentVariable("OctopusApiKey", $createApiKeyResult.ApiKey, "User")
    [environment]::SetEnvironmentVariable("OctopusApiKey", $createApiKeyResult.ApiKey, "Machine")

    #create an environment for the tentacles to go into
    $environment = New-Object Octopus.Client.Model.EnvironmentResource
    $environment.Name = "The-Env"
    $repository.Environments.Create($environment) | Out-Null

    set-content "c:\temp\octopus-configured.marker" ""
  }
}
catch
{
  Write-Output $_
  exit 1
}

