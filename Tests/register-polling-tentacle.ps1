# If for whatever reason this doesn't work, check this file:
Start-Transcript -path "C:\Octopus\Logs\configure-octopus-for-tentacle-tests.txt" -append

$OFS = "`r`n"
$OctopusURI = "http://localhost:81"
$octopusAdminUsername="OctoAdmin"
$octopusAdminPassword="SuperS3cretPassw0rd!"

# we have setup the tentacle via DSC, and given it a thumbprint, but have requested it to
# not register with the server. (ie, simulating the situation where tentacles cannot see the server)
# so, we need to register the tentacle outside of DSC

try
{
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

    $environment = $repository.Environments.FindByName("The-Env")

    $existingMachine = $repository.machines.findbyname("ListeningTentacleWithThumbprintWithoutAutoRegister")
    if ($null -ne $existingMachine) {
        $repository.machines.Delete($existingMachine)
    }

    $tentacleThumbprint = & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" "show-thumbprint" "--instance=ListeningTentacleWithThumbprintWithoutAutoRegister" "--nologo" "--thumbprint-only" "--console"

    $environmentId = $environment.id
    $role = "Test-Tentacle"
    $machineName = "ListeningTentacleWithThumbprintWithoutAutoRegister"

    $tentacleEndpoint = New-Object Octopus.Client.Model.EndPoints.ListeningTentacleEndpointResource
    $tentacleEndpoint.Thumbprint = $tentacleThumbprint
    $tentacleEndpoint.Uri = "https://localhost:10935"

    $tentacle = New-Object Octopus.Client.Model.MachineResource
    $tentacle.Endpoint = $tentacleEndpoint
    $tentacle.EnvironmentIds.Add($environmentId)
    $tentacle.Roles.Add($role)
    $tentacle.Name = $machineName

    $repository.Machines.Create($tentacle)
}
catch
{
  Write-Output $_
  exit 1
}

