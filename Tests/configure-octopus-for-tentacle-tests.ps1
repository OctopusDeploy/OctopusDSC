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

    #create an environment for the tentacles to go into
    $environment = $repository.Environments.CreateOrModify("The-Env") | Out-Null
    $repository.Environments.CreateOrModify("Env2") | Out-Null

    #create a project
    $projectGroup = $repository.ProjectGroups.Get("ProjectGroups-1")
    if($null -eq $projectGroup) {
      throw "Default Project group not found during configuration"
    }

    $lifecycle = $repository.Lifecycles.FindByName("Default Lifecycle")
    if($null -eq $lifecycle) {
      throw "Lifecycle 'Default Lifecycle' not found during configuration"
    }

    $project = $repository.Projects.CreateOrModify("Multi tenant project", $projectGroup, $lifecycle)

    # setup tag set
    $tagSetEditor = $repository.TagSets.CreateOrModify("Hosting")
    $tagSetEditor.AddOrUpdateTag("On premises", "Hosted on site", [Octopus.Client.Model.TagResource+StandardColor]::DarkGreen) | Out-Null
    $tagSetEditor.AddOrUpdateTag("Cloud", "Hosted in the cloud", [Octopus.Client.Model.TagResource+StandardColor]::LightBlue) | Out-Null
    $tagSet = $tagSetEditor.Instance

    $tenantEditor = $repository.Tenants.CreateOrModify("John")
    $tenantEditor.WithTag($tagSet.Tags[0]) | Out-Null
    $tenantEditor.ConnectToProjectAndEnvironments($project, $environment) | Out-Null

    # create a non-default Test Machine Policy w/ defaults
    $policyResource = $repository.MachinePolicies.GetTemplate()
    $policyResource.Name = "Test Policy"
    $policyResource.IsDefault = $false
    $policyResource.Description = "Test Machine Policy"
    $repository.MachinePolicies.Create($policyResource) | Out-Null

    #ensure we have a worker pool
    $workerpool = New-Object Octopus.Client.Model.WorkerPoolResource
    $workerpool.Name = "Secondary Worker Pool"
    $workerpool.Description = $WorkerPoolDescription
    $workerpool.SpaceId = $SpaceId
    $repository.WorkerPools.CreateOrModify($workerpool) | Out-Null

    $certificate = Invoke-RestMethod "$OctopusURI/api/configuration/certificates/certificate-global?apikey=$($createApiKeyResult.ApiKey)"
    $content = @{
        "OctopusServerUrl" = $OctopusURI;
        "OctopusApiKey" = $createApiKeyResult.ApiKey;
        "OctopusServerThumbprint" = $certificate.Thumbprint;
    }
    set-content "c:\temp\octopus-configured.marker" ($content | ConvertTo-Json)
    Stop-Transcript
  }
}
catch
{
  Write-Output $_
  Stop-Transcript
  exit 1
}

