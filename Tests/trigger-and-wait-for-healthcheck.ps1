# If for whatever reason this doesn't work, check this file:
Start-Transcript -path "C:\Octopus\Logs\trigger-and-wait-for-healthcheck.txt" -append

$OFS = "`r`n"
$OctopusURI = "http://localhost:81"
$OctopusAPIKey=$env:OctopusApiKey

try
{
  Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
  Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

  $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI, $OctopusAPIKey
  $repository = new-object Octopus.Client.OctopusRepository $endpoint
  $environments = $repository.Environments.FindAll()

  foreach($environment in $environments)
  {
    $header = @{ "X-Octopus-ApiKey" = $OctopusAPIKey }
    Write-Output "Creating healthcheck task for environment '$($environment.Name)'"
    $body = @{
        Name = "Health"
        Description = "Checking health of all machines in environment '$($environment.Name)'"
        Arguments = @{
            Timeout= "00:05:00"
            EnvironmentId = $environment.Id
        }
    } | ConvertTo-Json

    $result = Invoke-RestMethod $OctopusURI/api/tasks -Method Post -Body $body -Headers $header
    while (($result.State -ne "Success") -and ($result.State -ne "Failed") -and ($result.State -ne "Canceled") -and ($result.State -ne "TimedOut")) {
      Write-Output "Polling for healthcheck completion. Status is '$($result.State)'"
      Start-Sleep -Seconds 5
      $result = Invoke-RestMethod "$OctopusURI$($result.Links.Self)" -Headers $header
    }
    Write-Output "Healthcheck completed with status '$($result.State)'"
  }
}
catch
{
  Write-Output $_
  exit 1
}

