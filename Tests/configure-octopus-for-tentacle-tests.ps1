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

    #store the thumbprint of the server so wec an access it in tests
    $certificate = Invoke-RestMethod "$OctopusURI/api/configuration/certificates/certificate-global?apikey=$($createApiKeyResult.ApiKey)"
    [environment]::SetEnvironmentVariable("OctopusServerThumbprint", $certificate.Thumbprint, "User")
    [environment]::SetEnvironmentVariable("OctopusServerThumbprint", $certificate.Thumbprint, "Machine")

    #create an environment for the tentacles to go into
    $environment = New-Object Octopus.Client.Model.EnvironmentResource
    $environment.Name = "The-Env"
    $repository.Environments.Create($environment) | Out-Null

    #create a project
    $projectGroup = $repository.ProjectGroups.Get("ProjectGroups-1")
    if($null -eq $projectGroup)
    {
      throw "Default Project group not found during configuration"
    }

    $lifecycle = $repository.Lifecycles.FindByName("Default Lifecycle")
    if($null -eq $lifecycle)
    {
      throw "Lifecycle 'Default Lifecycle' not found during configuration"
    }

    $project = $repository.Projects.CreateOrModify("Multi tenant project", $projectGroup, $lifecycle)
    $project.Save() | Out-Null

    #enable Tenants feature  # as of 2019 versions, this is permanently on.
    #$featureConfig = $repository.FeaturesConfiguration.GetFeaturesConfiguration()
    #$featureConfig.IsMultiTenancyEnabled = $true
    #$repository.FeaturesConfiguration.ModifyFeaturesConfiguration($featureConfig) | Out-Null

    #reconnect after changing the feature config as the OctopusRepository caches some stuff
    $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
    $repository = new-object Octopus.Client.OctopusRepository $endpoint
    $repository.Users.SignIn($credentials)

    # setup tag set
    $tagSetEditor = $repository.TagSets.CreateOrModify("Hosting")
    $tagSetEditor.AddOrUpdateTag("On premises", "Hosted on site", [Octopus.Client.Model.TagResource+StandardColor]::DarkGreen) | Out-Null
    $tagSetEditor.AddOrUpdateTag("Cloud", "Hosted in the cloud", [Octopus.Client.Model.TagResource+StandardColor]::LightBlue) | Out-Null
    $tagSetEditor.Save() | Out-Null
    $tagSet = $tagSetEditor.Instance

    $project = $repository.Projects.FindByName("Multi tenant project")
    $environment = $repository.Environments.FindByName("The-Env")

    $tenantEditor = $repository.Tenants.CreateOrModify("John")
    $tenantEditor.WithTag($tagSet.Tags[0]) | Out-Null
    $tenantEditor.ConnectToProjectAndEnvironments($project, $environment) | Out-Null
    $tenantEditor.Save() | Out-Null

    # create a non-default Test Machine Policy w/ defaults
    $policyResource = new-object Octopus.Client.Model.MachinePolicyResource
    $policyResource.Name = "Test Policy"
    $policyResource.IsDefault = $false
    $policyResource.Description = "Test Machine Policy"
    $repository.MachinePolicies.Create($policyResource) | Out-Null

    set-content "c:\temp\octopus-configured.marker" ""
    Stop-Transcript
  }
}
catch
{
  Write-Output $_
  Stop-Transcript
  exit 1
}

