$defaultTentacleDownloadUrl = "https://octopus.com/downloads/latest/OctopusTentacle"
$defaultTentacleDownloadUrl64 = "https://octopus.com/downloads/latest/OctopusTentacle64"

# dot-source the helper file (cannot load as a module due to scope considerations)
. (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'OctopusDSCHelpers.ps1')

<#
    .SYNOPSIS
        Calls the specified API and returns the results converted from JSON

    .PARAMETER ServerUrl
        URL of the Octopus Deploy server

    .PARAMETER API
        Relative url for the API

    .PARAMETER APIKey
        The API key to use for making the call

    .EXAMPLE
        Get-APIResults -ServerUrl "http://OctopusServer" -API "/machines/all" -APIKey "API-SOMEAPIKEY"
#>
function Get-APIResults
{
    # Define parameters
    param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $ServerUrl,

        [Parameter(Mandatory=$true)]
        [System.String]
        $API,

        [Parameter(Mandatory=$true)]
        [System.String]
        $APIKey
    )

    # Check to see if the server url ends with a /
    if (!$ServerUrl.EndsWith("/"))
    {
        # Add trailing slash
        $ServerUrl = "$ServerUrl/"
    }
    
    # form the api endpoint
    $apiEndpoint = "{0}api{1}" -f $ServerUrl, $API

    # Call API and capture results
    $results = Invoke-WebRequest -Uri $apiEndpoint -Headers @{"X-Octopus-ApiKey"="$APIKey"} -UseBasicParsing 

    # return the result
    return ConvertFrom-Json -InputObject $results
}

<#
    .SYNOPSIS
        Gets reference to the specific machine

    .PARAMETER ServerUrl
        URL of the Octopus Deploy server

    .PARAMETER APIKey
        The API key to use for making the call 
        
    .PARAMETER Instance
        The instance name to find

    .EXAMPLE
        Get-APIResults -ServerUrl "http://OctopusServer" -API "/machines/all" -APIKey "API-SOMEAPIKEY"
#>

function Get-MachineFromOctopusServer
{
    # Define parameters
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $ServerUrl,

        [Parameter(Mandatory=$true)]
        [System.String]
        $APIKey,

        [Parameter()]
        [System.String]
        $Instance
    )

    # Get all the machines form Octopus
    $machines = Get-APIResults -ServerUrl $ServerUrl -APIKey $APIKey -API "/machines/all"

    # Get this machine's thumbprint
    $thumbprint = Get-TentacleThumbprint -Instance $Instance
    
    # Attempt to find this machine by machine name
    $machine = $machines | Where-Object {$_.Thumbprint -eq $thumbprint}

    # return the machine reference
    return $machine
}

<#
    .SYNOPSIS
        Gets reference to the specific machine

    .PARAMETER Instance
        Name of the instance to get the thumbprint for
    
    .EXAMPLE
        Get-TentacleThumbprint
#>

function Get-TentacleThumbprint
{
    # Define parameters
    param (
        [Parameter()]
        [System.String]
        $Instance
    )
    
    # Set location
    Push-Location "${env:ProgramFiles}\Octopus Deploy\Tentacle" 
    
    # Get the thumbprint of this tentacle
    $thumbprint = Invoke-Command {& .\tentacle.exe show-thumbprint --instance=$Instance} | Write-Output

    # Reset location
    Pop-Location

    # Return the thumbprint
    return $thumbprint
}

function Get-TargetResource {
    [OutputType([Hashtable])]
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",
        [ValidateSet("Listen", "Poll")]
        [string]$CommunicationMode = "Listen",
        [string]$ApiKey,
        [string]$DisplayName = "$($env:COMPUTERNAME)_$Name",
        [string]$OctopusServerUrl,
        [string[]]$Environments = "",
        [string[]]$Roles = "",
        [string]$Policy,
        [string[]]$Tenants = "",
        [string[]]$TenantTags = "",
        [string]$DefaultApplicationDirectory,
        [int]$ListenPort = 10933,
        [int]$TentacleCommsPort = 0,
        [int]$ServerPort = 10943,
        [string]$tentacleDownloadUrl = $defaultTentacleDownloadUrl,
        [string]$tentacleDownloadUrl64 = $defaultTentacleDownloadUrl64,
        [ValidateSet("PublicIp", "FQDN", "ComputerName", "Custom")]
        [string]$PublicHostNameConfiguration = "PublicIp",
        [string]$CustomPublicHostName,
        [string]$TentacleHomeDirectory = "$($env:SystemDrive)\Octopus",
        [bool]$RegisterWithServer = $true,
        [string]$OctopusServerThumbprint,
        [PSCredential]$TentacleServiceCredential,
        [string[]]$WorkerPools
    )
    Write-Verbose "Checking if Tentacle is installed"
    $installLocation = (Get-ItemProperty -path "HKLM:\Software\Octopus\Tentacle" -ErrorAction SilentlyContinue).InstallLocation
    $present = ($null -ne $installLocation)
    Write-Verbose "Tentacle present: $present"

    $currentEnsure = if ($present) { "Present" } else { "Absent" }

    $serviceName = (Get-TentacleServiceName $Name)
    Write-Verbose "Checking for Windows Service: $serviceName"
    $serviceInstance = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    $currentState = "Stopped"
    if ($null -ne $serviceInstance) {
        Write-Verbose "Windows service: $($serviceInstance.Status)"
        if ($serviceInstance.Status -eq "Running") {
            $currentState = "Started"
        }

        if ($currentEnsure -eq "Absent") {
            Write-Verbose "Since the Windows Service is still installed, the service is present"
            $currentEnsure = "Present"
        }
    }
    else {
        Write-Verbose "Windows service: Not installed"
        $currentEnsure = "Absent"
    }

    $originalDownloadUrl = $null
    if (Test-Path "$($env:SystemDrive)\Octopus\Octopus.DSC.installstate") {
        $originalDownloadUrl = (Get-Content -Raw -Path "$($env:SystemDrive)\Octopus\Octopus.DSC.installstate" | ConvertFrom-Json).TentacleDownloadUrl
    }

    return @{
        Name                = $Name;
        Ensure              = $currentEnsure;
        State               = $currentState;
        TentacleDownloadUrl = $originalDownloadUrl;
    };
}

# test a variable has a value (whether its an array or string)
function Test-Value($value) {
    if ($null -eq $value) { return $false }
    if ($value -eq "") { return $false }
    if ($value.length -eq 0) { return $false }
    if ($value.length -eq 1 -and $value[0].length -eq 0) { return $false }
    return $true
}

function Confirm-RegistrationParameter {
    param (
        [bool]$RegisterWithServer,
        [string[]]$Environments,
        [string[]]$Roles,
        [string]$Policy,
        [string[]]$Tenants,
        [string[]]$TenantTags,
        [string]$OctopusServerUrl,
        [string]$ApiKey
    )

    if ((Test-Value($Roles)) -and (-not ($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle not to be registered with the server, but still provided a the 'Roles' configuration argument. " + `
            "Please remove the 'Roles' configuration argument or set 'RegisterWithServer = `$True'."
    } elseif ((Test-Value($Environments)) -and (-not ($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle not to be registered with the server, but still provided a the 'Environments' configuration argument. " + `
            "Please remove the 'Environments' configuration argument or set 'RegisterWithServer = `$True'."
    } elseif ((Test-Value($Tenants)) -and (-not ($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle not to be registered with the server, but still provided a the 'Tenants' configuration argument. " + `
            "Please remove the 'Tenants' configuration argument or set 'RegisterWithServer = `$True'."
    } elseif ((Test-Value($TenantTags)) -and (-not ($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle not to be registered with the server, but still provided a the 'TenantTags' configuration argument. " + `
            "Please remove the 'TenantTags' configuration argument or set 'RegisterWithServer = `$True'."
    } elseif ((Test-Value($Policy)) -and (-not ($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle not to be registered with the server, but still provided a the 'Policy' configuration argument. " + `
            "Please remove the 'Policy' configuration argument or set 'RegisterWithServer = `$True'."
    } elseif ((-not (Test-Value($OctopusServerUrl))) -and (($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle to be registered with the server, but not provided the 'OctopusServerUrl' configuration argument. " + `
            "Please specify the 'OctopusServerUrl' configuration argument or set 'RegisterWithServer = `$False'."
    } elseif ((-not (Test-Value($ApiKey))) -and (($RegisterWithServer))) {
        throw "Invalid configuration requested. " + `
            "You have asked for the Tentacle to be registered with the server, but not provided the 'ApiKey' configuration argument. " + `
            "Please specify the 'ApiKey' configuration argument or set 'RegisterWithServer = `$False'."
    }
}

function Confirm-RequestedState() {
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started"
    )
    if ($Ensure -eq "Absent" -and $State -eq "Started") {
        throw "Invalid configuration requested. " + `
            "You have asked for the service to not exist, but also be running at the same time. " + `
            "You probably want 'State = `"Stopped`"'."
    }
}

function Set-TargetResource {
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",
        [ValidateSet("Listen", "Poll")]
        [string]$CommunicationMode = "Listen",
        [string]$ApiKey,
        [string]$OctopusServerUrl,
        [string]$DisplayName = "$($env:COMPUTERNAME)_$Name",
        [string[]]$Environments = "",
        [string[]]$Roles = "",
        [string]$Policy,
        [string[]]$Tenants = "",
        [string[]]$TenantTags = "",
        [string]$DefaultApplicationDirectory = "$($env:SystemDrive)\Applications",
        [int]$ListenPort = 10933,
        [int]$TentacleCommsPort = 0,
        [int]$ServerPort = 10943,
        [string]$tentacleDownloadUrl = $defaultTentacleDownloadUrl,
        [string]$tentacleDownloadUrl64 = $defaultTentacleDownloadUrl64,
        [ValidateSet("PublicIp", "FQDN", "ComputerName", "Custom")]
        [string]$PublicHostNameConfiguration = "PublicIp",
        [string]$CustomPublicHostName,
        [string]$TentacleHomeDirectory = "$($env:SystemDrive)\Octopus",
        [bool]$RegisterWithServer = $true,
        [string]$OctopusServerThumbprint,
        [PSCredential]$TentacleServiceCredential,
        [string[]]$WorkerPools
    )
    Confirm-RequestedState $Ensure $State
    Confirm-RegistrationParameter $RegisterWithServer `
        -Environments $Environments `
        -Roles $Roles `
        -Policy $Policy `
        -Tenants $Tenants `
        -TenantTags $TenantTags `
        -OctopusServerUrl $OctopusServerUrl `
        -ApiKey $ApiKey


    $currentResource = (Get-TargetResource -Name $Name)

    Write-Verbose "Configuring Tentacle..."

    if ($State -eq "Stopped" -and $currentResource["State"] -eq "Started") {
        $serviceName = (Get-TentacleServiceName $Name)
        Write-Verbose "Stopping $serviceName"
        Stop-Service -Name $serviceName -Force
    }

    if ($Ensure -eq "Absent" -and $currentResource["Ensure"] -eq "Present") {
        if ($RegisterWithServer) {
            Remove-WorkerPoolRegistration -name $Name -apiKey $ApiKey -octopusServerUrl $OctopusServerUrl
            Remove-TentacleRegistration -name $Name -apiKey $ApiKey -octopusServerUrl $OctopusServerUrl
        }

        $serviceName = (Get-TentacleServiceName $Name)
        Write-Verbose "Deleting service $serviceName..."
        Invoke-AndAssert { & sc.exe delete $serviceName }

        $otherServices = @(Get-CimInstance win32_service | Where-Object {$_.PathName -like "`"$($env:ProgramFiles)\Octopus Deploy\Tentacle\Tentacle.exe*"})

        if ($otherServices.length -eq 0) {
            # Uninstall msi
            Write-Verbose "Uninstalling Tentacle..."
            if (-not (Test-Path "$TentacleHomeDirectory\logs")) {
                Write-Verbose "Log directory does not exist. Creating..."
                New-Item -type Directory "$TentacleHomeDirectory\logs" | Out-Null
            }
            $tentaclePath = "$TentacleHomeDirectory\Tentacle.msi"
            $msiLog = "$TentacleHomeDirectory\logs\Tentacle.msi.uninstall.log"
            if (test-path $tentaclePath) {
                $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/x `"$tentaclePath`" /quiet /l*v `"$msiLog`"" -Wait -Passthru).ExitCode
                Write-Verbose "Tentacle MSI installer returned exit code $msiExitCode"
                if ($msiExitCode -ne 0) {
                    throw "Removal of Tentacle failed, MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
                }
            }
            else {
                throw "Tentacle cannot be removed, because the MSI could not be found."
            }
        }
        else {
            Write-Verbose "Skipping uninstall, as other tentacles still exist:"
            foreach ($otherService in $otherServices) {
                Write-Verbose " - $($otherService.Name)"
            }
        }
    }
    elseif ($Ensure -eq "Present" -and $currentResource["Ensure"] -eq "Absent") {
        Write-Verbose "Installing Tentacle..."
        New-Tentacle -name $Name `
            -apiKey $ApiKey `
            -octopusServerUrl $OctopusServerUrl `
            -port $ListenPort `
            -tentacleCommsPort $TentacleCommsPort `
            -displayName $DisplayName `
            -environments $Environments `
            -roles $Roles `
            -policy $Policy `
            -tenants $Tenants `
            -tenantTags $TenantTags `
            -defaultApplicationDirectory $DefaultApplicationDirectory `
            -tentacleDownloadUrl $tentacleDownloadUrl `
            -tentacleDownloadUrl64 $tentacleDownloadUrl64 `
            -communicationMode $CommunicationMode `
            -serverPort $ServerPort `
            -publicHostNameConfiguration $PublicHostNameConfiguration `
            -customPublicHostName $CustomPublicHostName `
            -tentacleHomeDirectory $TentacleHomeDirectory `
            -registerWithServer $RegisterWithServer `
            -octopusServerThumbprint $OctopusServerThumbprint `
            -TentacleServiceCredential $TentacleServiceCredential `
            -WorkerPools $WorkerPools

        Write-Verbose "Tentacle installed!"
    }
    elseif ($Ensure -eq "Present" -and $currentResource["TentacleDownloadUrl"] -ne (Get-TentacleDownloadUrl $tentacleDownloadUrl $tentacleDownloadUrl64)) {
        Write-Verbose "Upgrading Tentacle..."
        $serviceName = (Get-TentacleServiceName $Name)
        Stop-Service -Name $serviceName
        Install-Tentacle $tentacleDownloadUrl $tentacleDownloadUrl64 $TentacleHomeDirectory
        if ($State -eq "Started") {
            Start-Service $serviceName
        }
        Write-Verbose "Tentacle upgraded!"
    }
    elseif ($Ensure -eq "Present" -and $currentResource["Ensure"] -eq "Present")
    {
        
        # Re-register tentacle
        Register-Tentacle -name $Name `
        -apiKey $ApiKey `
        -octopusServerUrl $OctopusServerUrl `
        -environments $Environments `
        -roles $Roles `
        -tenants $Tenants `
        -tenantTags $TenantTags `
        -policy $Policy `
        -communicationMode $CommunicationMode `
        -displayName $DisplayName `
        -publicHostNameConfiguration $PublicHostNameConfiguration `
        -customPublicHostName $CustomPublicHostName `
        -port $ListenPort `
        -serverPort $ServerPort `
        -tentacleCommsPort $TentacleCommsPort `
        

        
        # Check worker pools
        if (($null -ne $WorkerPools) -and ($WorkerPools.Count -gt 0))
        {
            # Add worker pools
            Write-Verbose "Adding $Name to worker pools $($workerPools -join ", ")."

            # Add the tentacle to specified worker pools
            Add-TentacleToWorkerPools -name $Name -octopusServerUrl $OctopusServerUrl -apiKey $ApiKey -workerPools $WorkerPools
        }
    }

    if ($State -eq "Started" -and $currentResource["State"] -eq "Stopped") {
        $serviceName = (Get-TentacleServiceName $Name)
        Write-Verbose "Starting $serviceName"
        Start-Service -Name $serviceName
    }

    Write-Verbose "Finished"
}

function Test-TargetResource {
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",
        [ValidateSet("Listen", "Poll")]
        [string]$CommunicationMode = "Listen",
        [string]$ApiKey,
        [string]$OctopusServerUrl,
        [string]$DisplayName = "$($env:COMPUTERNAME)_$Name",
        [string[]]$Environments = "",
        [string[]]$Roles = "",
        [string]$Policy,
        [string[]]$Tenants = "",
        [string[]]$TenantTags = "",
        [string]$DefaultApplicationDirectory,
        [int]$ListenPort = 10933,
        [int]$TentacleCommsPort = 0,
        [int]$ServerPort = 10943,
        [string]$tentacleDownloadUrl = $defaultTentacleDownloadUrl,
        [string]$tentacleDownloadUrl64 = $defaultTentacleDownloadUrl64,
        [ValidateSet("PublicIp", "FQDN", "ComputerName", "Custom")]
        [string]$PublicHostNameConfiguration = "PublicIp",
        [string]$CustomPublicHostName,
        [string]$TentacleHomeDirectory = "$($env:SystemDrive)\Octopus",
        [bool]$RegisterWithServer = $true,
        [string]$OctopusServerThumbprint,
        [PSCredential]$TentacleServiceCredential,
        [string[]]$WorkerPools
    )

    $currentResource = (Get-TargetResource -Name $Name)

    $ensureMatch = $currentResource["Ensure"] -eq $Ensure
    Write-Verbose "Ensure: $($currentResource["Ensure"]) vs. $Ensure = $ensureMatch"
    if (!$ensureMatch) {
        return $false
    }

    $stateMatch = $currentResource["State"] -eq $State
    Write-Verbose "State: $($currentResource["State"]) vs. $State = $stateMatch"
    if (!$stateMatch) {
        return $false
    }

    if ($null -ne $currentResource["TentacleDownloadUrl"]) {
        $requestedDownloadUrl = Get-TentacleDownloadUrl $tentacleDownloadUrl $tentacleDownloadUrl64
        $downloadUrlsMatch = $requestedDownloadUrl -eq $currentResource["TentacleDownloadUrl"]
        Write-Verbose "Download Url: $($currentResource["TentacleDownloadUrl"]) vs. $requestedDownloadUrl = $downloadUrlsMatch"
        if (!$downloadUrlsMatch) {
            return $false
        }
    }

    # Check Ensure value
    if ($Ensure -eq "Present")
    {
        # Get reference to machine
        $machine = Get-MachineFromOctopusServer -ServerUrl $OctopusServerUrl -APIKey $ApiKey -Instance $Name

        # Check to see if machine returned anything
        if ($null -ne $machine)
        {
            # Compare environment counts
            if ($Environments.Count -ne $machine.EnvironmentIds.Count)
            {
                # Display message
                Write-Verbose "Environment counts do not match, not in desired state."
                
                # Not in desired state
                return $false
            }
            else 
            {
                # Compare environment names
                foreach ($environmentId in $machine.EnvironmentIds)
                {
                    # Get environment reference
                    $environment = Get-APIResults -ServerUrl $OctopusServerUrl -ApiKey $ApiKey -API "/environments/$environmentId"

                    # Verify that the environment is in the list of environments
                    if ($Environments -notcontains $environment.Name)
                    {
                        # Display message
                        Write-Verbose "Machine currently has environment $($environment.Name), which is not listed in the passed in Environment list.  Machine is not in desired state."
                        
                        # Not in desired state
                        return $false
                    }
                }
            }

            # Get reference to worker pools
            $octoWorkerPools = Get-APIResults -ServerUrl $OctopusServerUrl -ApiKey $ApiKey -API "/workerpools/all"
<#
            # Compare worker assignments
            foreach ($octoWorkerPool in $octoWorkerPools)
            {
                # Get reference to the worker pool
                $workerPoolObject = Get-APIResults -ServerUrl $OctopusServerUrl -APIKey $ApiKey -API "/workerpools/$($octoWorkerPool.Id)/workers"

                # Check to see if worker pool has this $Name in it
                if (($null -eq ($workerPoolObject.Items | Where-Object {$_.Name -eq $machine.Name })) -and ($null -ne ($WorkerPools | Where-Object {$_ -eq $octoWorkerPool.Name})))
                {
                    # Display message
                    Write-Verbose "$($machine.Name) is not a member of Worker Pool $($octoWorkerPool.Name) and should be.  $($machine.Name) is not in desired state."

                    # Not in desired state
                    return $false
                }
            }
 #>           
            # Compare worker assignments -- remove this once you've done the loop above
            foreach ($workerPool in $WorkerPools)
            {
                # Get reference to specific pool
                $octoWorkerPool = $octoWorkerPools | Where-Object {$_.Name -eq $workerPool}

                # Check to see if the pool was found
                if ($null -ne $octoWorkerPool)
                {
                    # Get reference to the pool object
                    $workerPoolObject = Get-APIResults -ServerUrl $OctopusServerUrl -ApiKey $ApiKey -API "/workerpools/$($octoWorkerPool.Id)/workers"

                    # See if the machine is in the worker pool list
                    if ($null -eq ($workerPoolObject.Items | Where-Object {$_.Name -eq $machine.Name}))
                    {
                        # Display message
                        Write-Verbose "$($octoWorkerPool.Name) does not contain $($machine.Name), not in desired state."
                        
                        # Not in desired state
                        return $false
                    }
                }
                else 
                {
                    # Not in desired state
                    #return $false
                    # Display warning
                    Write-Verbose "Warning - worker pool $workerPool does not exist."
                }
            }

            # Check role counts
            if ($Roles.Count -ne $machine.Roles.Count)
            {
                # Display message
                Write-Verbose "Role counts do not match, not in desired state."

                # return false
                return $false
            }
            else
            {
                # Compare array contents
                $differences = Compare-Object -ReferenceObject $Roles -DifferenceObject $machine.Roles

                # Check to see if $differences is null
                if ($null -ne $differences)
                {
                    # Display message
                    Write-Verbose "Tentacle roles do not match specified roles, not in desired state."

                    # return false
                    return $false
                }
            }
        }
    }

    return $true
}

function Get-TentacleServiceName {
    param ( [string]$instanceName )

    if ($instanceName -eq "Tentacle") {
        return "OctopusDeploy Tentacle"
    }
    else {
        return "OctopusDeploy Tentacle: $instanceName"
    }
}

# After the Tentacle is registered with Octopus, Tentacle listens on a TCP port, and Octopus connects to it. The Octopus server
# needs to know the public IP address to use to connect to this Tentacle instance.
Function Get-MyPublicIPAddress {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
    param()
    Write-Verbose "Getting public IP address"

    [Net.ServicePointManager]::SecurityProtocol = @(
        [Net.SecurityProtocolType]::Tls12,
        [Net.SecurityProtocolType]::Tls11
    )

    $publicIPServices = @('https://api.ipify.org/', 'https://canhazip.com/', 'https://ipv4bot.whatismyipaddress.com/')
    $ip = $null
    $x = 0
    while($null -eq $ip -and $x -lt $publicIPServices.Length) {
        try {
            $target = $publicIpServices[$x++]
            $ip = Invoke-RestMethod -Uri $target
        }
        catch {
            Write-Verbose "Failed to find a public IP via $target. Reason: $_ "
        }
    }

    if($null -eq $ip) {
        throw "Unable to determine your Public IP address. Please supply a hostname or IP address via the PublicHostName parameter."
    }

    try
    {
        [Ipaddress]$ip | Out-Null
    }
    catch
    {
        throw "Detected Public IP address '$ip', but we we couldn't parse it as an IPv4 address."
    }

    return $ip
}


function Install-Tentacle {
    param (
        [string]$tentacleDownloadUrl,
        [string]$tentacleDownloadUrl64,
        [string]$tentacleHomeDirectory
    )
    Write-Verbose "Beginning Tentacle installation"

    $actualTentacleDownloadUrl = Get-TentacleDownloadUrl $tentacleDownloadUrl $tentacleDownloadUrl64

    if (-not (Test-Path $tentacleHomeDirectory)) {
        Write-Verbose "Tentacle Home directory does not exist. Creating..."
        New-Item -Path "$tentacleHomeDirectory" -ItemType Directory | Out-Null
    }
    $tentaclePath = "$tentacleHomeDirectory\Tentacle.msi"
    if ((Test-Path $tentaclePath) -eq $true) {
        Remove-Item $tentaclePath -force
    }
    Write-Verbose "Downloading Octopus Tentacle MSI from $actualTentacleDownloadUrl to $tentaclePath"
    Request-File $actualTentacleDownloadUrl $tentaclePath

    Write-Verbose "Installing MSI..."
    if (-not (Test-Path $env:TEMP)) {
        Write-Verbose "Configured temp folder does not currently exist, creating..."
        New-Item $env:TEMP -ItemType Directory -force | Out-Null # an edge case when the env var exists but the folder does not
    }

    if (-not (Test-Path "$TentacleHomeDirectory\logs")) {
        Write-Verbose "Log directory not found. Creating..."
        New-Item -type Directory "$TentacleHomeDirectory\logs" -force | Out-Null
    }
    $msiLog = "$TentacleHomeDirectory\logs\Tentacle.msi.log"
    $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tentaclePath`" /quiet /l*v `"$msiLog`"" -Wait -Passthru).ExitCode
    Write-Verbose "Tentacle MSI installer returned exit code $msiExitCode"
    if ($msiExitCode -ne 0) {
        throw "Installation of the Tentacle MSI failed; MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
    }

    if (-not (Test-Path "$($env:SystemDrive)\Octopus")) {
        Write-Verbose "$($env:SystemDrive)\Octopus not found. Creating..."
        New-Item -type Directory "$($env:SystemDrive)\Octopus" -Force | Out-Null
    }
    @{ "TentacleDownloadUrl" = $actualTentacleDownloadUrl } | ConvertTo-Json | set-content "$($env:SystemDrive)\Octopus\Octopus.DSC.installstate"
}

function New-Tentacle {
    param (
        [Parameter(Mandatory = $True)]
        [string]$name,
        [string]$apiKey,
        [string]$octopusServerUrl,
        [Parameter(Mandatory = $False)]
        [string[]]$environments = "",
        [Parameter(Mandatory = $False)]
        [string[]]$roles = "",
        [Parameter(Mandatory = $False)]
        [string[]]$tenants = "",
        [Parameter(Mandatory = $False)]
        [string[]]$tenantTags = "",
        [Parameter(Mandatory = $False)]
        [string]$policy,
        [int]$port = 10933,
        [int]$tentacleCommsPort = 0,
        [string]$displayName,
        [string]$defaultApplicationDirectory,
        [string]$tentacleDownloadUrl,
        [string]$tentacleDownloadUrl64,
        [ValidateSet("Listen", "Poll")]
        [string]$communicationMode = "Listen",
        [int]$serverPort = 10943,
        [ValidateSet("PublicIp", "FQDN", "ComputerName", "Custom")]
        [string]$publicHostNameConfiguration = "PublicIp",
        [string]$customPublicHostName,
        [string]$tentacleHomeDirectory = "$($env:SystemDrive)\Octopus",
        [bool]$registerWithServer = $true,
        [Parameter(Mandatory = $False)]
        [string]$octopusServerThumbprint,
        [PSCredential]$TentacleServiceCredential,
        [string[]] $workerPools
    )


    Install-Tentacle $tentacleDownloadUrl $tentacleDownloadUrl64 $tentacleHomeDirectory

    if ($communicationMode -eq "Listen") {
        $windowsFirewall = Get-Service -Name MpsSvc
        if ($windowsFirewall.Status -eq "Running") {

            # Check to see if the firewall rule already exists
            $rules = Invoke-Command {& netsh.exe advfirewall firewall show rule name="Octopus Tentacle: $Name"} | Write-Output

            if ($rules -eq "No rules match the specified criteria.")
			{
				Write-Verbose "Open port $port on Windows Firewall"
				Invoke-AndAssert { & netsh.exe advfirewall firewall add rule protocol=TCP dir=in localport=$port action=allow name="Octopus Tentacle: $Name" }
			}
            else
            {
                Write-Verbose "Tentacle firewall rule already exists, skipping firewall rule addition"
            }
        }
        else {
            Write-Verbose "Windows Firewall Service is not running... skipping firewall rule addition"
        }
    }

    Write-Verbose "Configuring and registering Tentacle"

    Push-Location "${env:ProgramFiles}\Octopus Deploy\Tentacle"

    $tentacleAppDirectory = $DefaultApplicationDirectory
    $tentacleConfigFile = "$tentacleHomeDirectory\$Name\Tentacle.config"
    Write-Verbose "Tentacle configuration set as $tentacleConfigFile"
    Invoke-AndAssert { & .\tentacle.exe create-instance --instance $name --config "$tentacleConfigFile" --console }
    Invoke-AndAssert { & .\tentacle.exe configure --instance $name --home "$tentacleHomeDirectory" --console }
    Invoke-AndAssert { & .\tentacle.exe configure --instance $name --app "$tentacleAppDirectory" --console }
    Invoke-AndAssert { & .\tentacle.exe new-certificate --instance $name --console }

    if (($null -ne $octopusServerThumbprint) -and ($octopusServerThumbprint -ne "")) {
        Invoke-AndAssert { & .\tentacle.exe configure --instance $name --trust $octopusServerThumbprint --console }
    }

    if ($CommunicationMode -eq "Listen") {
        Invoke-AndAssert { & .\tentacle.exe configure --instance $name --port $port --console }
    }
    else {
        Invoke-AndAssert { & .\tentacle.exe configure --instance $name --port $port --noListen "True" --console }
    }

    $serviceArgs = @(
        'service',
        '--install',
        '--instance', $name,
        '--console',
        '--reconfigure'
    )

    if ($TentacleServiceCredential) {
        Write-Verbose "Adding Service identity to installation command"

        $serviceArgs += @(
            '--username', $TentacleServiceCredential.UserName
            '--password', $TentacleServiceCredential.GetNetworkCredential().Password
        )
    }

    Invoke-AndAssert { & .\tentacle.exe ($serviceArgs) }

    # Reset location 
    Pop-Location

    if ($registerWithServer) {        

        if (($null -ne $octopusServerThumbprint) -and ($octopusServerThumbprint -ne "")) {
            Invoke-AndAssert { & .\tentacle.exe configure --instance $name --trust $octopusServerThumbprint --console }
        }

        # Register the tentacle
        Register-Tentacle -name $name `
        -apiKey $apiKey `
        -octopusServerUrl $octopusServerUrl `
        -environments $environments `
        -roles $roles `
        -tenants $tenants `
        -tenantTags $tenantTags `
        -policy $policy `
        -communicationMode $communicationMode `
        -displayName $displayName `
        -publicHostNameConfiguration $publicHostNameConfiguration `
        -customPublicHostName $customPublicHostName `
        -serverPort $serverPort `
        -port $port `
        -tentacleCommsPort $tentacleCommsPort

        # Check worker pools
        if (($null -ne $workerPools) -and ($workerPools.Count -gt 0))
        {
            # Add the worker pools
            Add-TentacleToWorkerPools -name $name -octopusServerUrl $octopusServerUrl -apiKey $apiKey -workerPools $workerPools
        }
    } 
    else {
        Write-Verbose "Skipping registration with server as 'RegisterWithServer' is set to '$registerWithServer'"
    }
    Pop-Location
    Write-Verbose "Tentacle commands complete"
}

function Get-PublicHostName {
    param (
        [ValidateSet("PublicIp", "FQDN", "ComputerName", "Custom")]
        [string]$publicHostNameConfiguration = "PublicIp",
        [string]$customPublicHostName
    )
    if ($publicHostNameConfiguration -eq "Custom") {
        $publicHostName = $customPublicHostName
    }
    elseif ($publicHostNameConfiguration -eq "FQDN") {
        $computer = Get-CimInstance win32_computersystem
        $publicHostName = "$($computer.DNSHostName).$($computer.Domain)"
    }
    elseif ($publicHostNameConfiguration -eq "ComputerName") {
        $publicHostName = $env:COMPUTERNAME
    }
    else {
        $publicHostName = Get-MyPublicIPAddress
    }
    $publicHostName = $publicHostName.Trim()
    return $publicHostName
}

function Get-TentacleDownloadUrl {
    param (
        [string]$tentacleDownloadUrl,
        [string]$tentacleDownloadUrl64
    )

    if ([IntPtr]::Size -eq 4) {
        return $tentacleDownloadUrl
    }
    return $tentacleDownloadUrl64
}

function Remove-TentacleRegistration {
    param (
        [Parameter(Mandatory = $True)]
        [string]$name,
        [Parameter(Mandatory = $True)]
        [string]$apiKey,
        [Parameter(Mandatory = $True)]
        [string]$octopusServerUrl
    )

    $tentacleDir = "${env:ProgramFiles}\Octopus Deploy\Tentacle"
    if ((test-path $tentacleDir) -and (test-path "$tentacleDir\tentacle.exe")) {
        Write-Verbose "Beginning Tentacle deregistration"
        Write-Verbose "Tentacle commands complete"
        Push-Location $tentacleDir
        Invoke-AndAssert { & .\tentacle.exe deregister-from --instance "$name" --server $octopusServerUrl --apiKey $apiKey --console }
        Pop-Location
    }
    else {
        Write-Verbose "Could not find Tentacle.exe"
    }
}

function Remove-WorkerPoolRegistration
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$octopusServerUrl,
        [Parameter()]
        [string]$apiKey,
        [Parameter()]
        [PSCredential]$TentacleServiceCredential,
        [Parameter(Mandatory = $true)]
        [string]$name
    )

    # Set tentacle location
    $tentacleDir = "${env:ProgramFiles}\Octopus Deploy\Tentacle"

    # Check to make sure the folder and the file exist
    if ((Test-Path -Path $tentacleDir) -and (Test-Path -Path "$tentacleDir\tentacle.exe"))
    {
        # Display message
        Write-Verbose "Deregistering $($env:ComputerName) from worker pools"

        # Declare argument list
        $argumentList = @(
            "deregister-worker",
            "--instance", $name,
            "--server", $octopusServerUrl,
            "--console"
        )

        # Set the location
        Push-Location -Path $tentacleDir

        # Determine which authentication mechanism ot use
        if (![string]::IsNullOrEmpty($apiKey))
        {
            # Add api key to argument list
            $argumentList += @(
                "--apiKey", $apiKey
            )
        }
        elseif (![string]::IsNullOrEmpty($TentacleServiceCredential))
        {
            # Add username and password to argument list
            $argumentList += @(
                "--username", $TentacleServiceCredential.UserName,
                "--password", $TentacleServiceCredential.GetNetworkCredential().Password
            )
        }
        else 
        {
            # Throw an error
            throw "Both APIKey and TentacleServiceCredential are null!"    
        }

        # Execute teh process
        Invoke-AndAssert {&.\tentacle.exe ($argumentList)}
    }
    else 
    {
        throw "Could not find Tentacle.exe"    
    }
}

function Add-TentacleToWorkerPools
{
    # Define parameters
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $name,

        [Parameter(Mandatory = $true)]
        [String]
        $octopusServerUrl,
        
        [Parameter()]
        [string]
        $apiKey,
        
        [Parameter()]
        [PSCredential]
        $TentacleServiceCredential,

        [Parameter()]
        [String[]]
        $workerPools
    )

    # Set tentacle location
    $tentacleDir = "${env:ProgramFiles}\Octopus Deploy\Tentacle"

    # Check to make sure the folder and the file exist
    if ((Test-Path -Path $tentacleDir) -and (Test-Path -Path "$tentacleDir\tentacle.exe"))
    {
        # Display message
        Write-Verbose "Adding $($env:COMPUTERNAME) to pool(s) $([System.String]::Join(", ", $workerPools))"

        # Create argument list
        $argumentList = @(
            "register-worker",
            "--instance", $name,
            "--server", $octopusServerUrl,
            "--force"
        )

        # Check to see which authentication mechanism to use
        if (![string]::IsNullOrEmpty($apiKey))
        {
            # Add to argument list
            $argumentList += @(
                "--apiKey", $apiKey
            )
        }
        elseif (![string]::IsNullOrEmpty($TentacleServiceCredential))
        {
            # Add to argument list
            $argumentList += @(
                "--username", $TentacleServiceCredential.UserName,
                "--password", $TentacleServiceCredential.GetNetworkCredential().Password
            )
        }
        else 
        {
            # Throw an error
            throw "Both APIKey and TentacleServiceCredential are null!"    
        }

        # Loop through work pools
        foreach ($workerPool in $workerPools)
        {
            # Add pool to the arguments
            $argumentList += @(
                "--workerpool", $workerPool
            )
        }

        # Set the location
        Push-Location -Path $tentacleDir
        
        # Execute the process
        Invoke-AndAssert { &.\tentacle.exe ($argumentList)}
    }
}

function Register-Tentacle
{
    # Define parameters
    param (
        [string]$name,
        [string]$apiKey,
        [string]$octopusServerUrl,
        [Parameter(Mandatory = $False)]
        [string[]]$environments = "",
        [Parameter(Mandatory = $False)]
        [string[]]$roles = "",
        [Parameter(Mandatory = $False)]
        [string[]]$tenants = "",
        [Parameter(Mandatory = $False)]
        [string[]]$tenantTags = "",
        [Parameter(Mandatory = $False)]
        [string]$policy,
        [ValidateSet("Listen", "Poll")]
        [string]$communicationMode = "Listen",
        [string]$displayName,
        [string]$publicHostNameConfiguration = "PublicIp",
        [string]$customPublicHostName,
        [int]$serverPort = 10943,
        [int]$port = 10933,
        [int]$tentacleCommsPort = 0
    )

    if ($port -eq 0) {
        $port = 10933
    }
    if ($tentacleCommsPort -eq 0) {
        $tentacleCommsPort = $port
    }

    # Define working variables
    $registerArguments = @(
        "register-with",
        "--instance", $name,
        "--server", $octopusServerUrl,
        "--name", $displayName,
        "--apiKey", $apiKey,
        "--force",
        "--console"
    )

    if (($null -ne $policy) -and ($policy -ne "")) {
        $registerArguments += @("--policy", $policy)
    }

    if ($CommunicationMode -eq "Listen") {
        $publicHostName = Get-PublicHostName $publicHostNameConfiguration $customPublicHostName
        Write-Verbose "Public host name: $publicHostName"
        $registerArguments += @(
            "--comms-style", "TentaclePassive",
            "--publicHostName", $publicHostName
        )
        if ($tentacleCommsPort -ne $port) {
            $registerArguments += @("--tentacle-comms-port", $tentacleCommsPort)
        }
    }
    else {
        $registerArguments += @(
            "--comms-style", "TentacleActive",
            "--server-comms-port", $serverPort
        )
    }

    if ($environments -ne "") {
        foreach ($environment in $environments) {
            foreach ($e2 in $environment.Split(',')) {
                $registerArguments += "--environment"
                $registerArguments += $e2.Trim()
            }
        }
    }

    if ($roles -ne "") {
        foreach ($role in $roles) {
            foreach ($r2 in $role.Split(',')) {
                $registerArguments += "--role"
                $registerArguments += $r2.Trim()
            }
        }
    }

    if ($tenants -ne "") {
        foreach ($tenant in $tenants) {
            foreach ($t2 in $tenant.Split(',')) {
                $registerArguments += "--tenant"
                $registerArguments += $t2.Trim()
            }
        }
    }

    if ($tenantTags -ne "") {
        foreach ($tenantTag in $tenantTags) {
            foreach ($tt2 in $tenantTag.Split(',')) {
                $registerArguments += "--tenanttag"
                $registerArguments += $tt2.Trim()
            }
        }
    }

    # Set the location
    Push-Location "${env:ProgramFiles}\Octopus Deploy\Tentacle"

    Write-Verbose "Registering with arguments: $registerArguments"
    Invoke-AndAssert { & .\tentacle.exe ($registerArguments) }    

    # Reset location 
    Pop-Location
}