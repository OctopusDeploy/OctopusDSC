function Get-TargetResource
{
  [OutputType([Hashtable])]
  param (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [ValidateSet("Started", "Stopped")]
    [string]$State = "Started",
    [ValidateNotNullOrEmpty()]
    [string]$DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WebListenPrefix,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SqlDbConnectionString,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OctopusAdminUsername,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OctopusAdminPassword,
    [bool]$upgradeCheck = $true,
    [bool]$upgradeCheckWithStatistics = $true,
    [string]$webAuthenticationMode = 'UsernamePassword',
    [bool]$forceSSL = $false,
    [int]$listenPort = 10943
  )

  Write-Verbose "Checking if Octopus Server is installed"
  $installLocation = (Get-ItemProperty -path "HKLM:\Software\Octopus\Octopus" -ErrorAction SilentlyContinue).InstallLocation
  $present = ($null -ne $installLocation)
  Write-Verbose "Octopus Server present: $present"

  $existingEnsure = if ($present) { "Present" } else { "Absent" }

  $serviceName = (Get-ServiceName $Name)
  Write-Verbose "Checking for Windows Service: $serviceName"
  $serviceInstance = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
  $existingState = "Stopped"
  if ($null -ne $serviceInstance)
  {
    Write-Verbose "Windows service: $($serviceInstance.Status)"
    if ($serviceInstance.Status -eq "Running")
    {
      $existingState = "Started"
    }

    if ($existingEnsure -eq "Absent")
    {
      Write-Verbose "Since the Windows Service is still installed, the service is present"
      $existingEnsure = "Present"
    }
  }
  else
  {
    Write-Verbose "Windows service: Not installed"
    $existingEnsure = "Absent"
  }

  $existingDownloadUrl = $null
  if (($existingEnsure -eq "Present") -and (Test-Path ("$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate"))) {
    $existingDownloadUrl = (Get-Content -Raw -Path "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate" | ConvertFrom-Json).TentacleDownloadUrl
  }

  $existingWebListenPrefix = $null
  $existingSqlDbConnectionString = $null
  if ($existingEnsure -eq "Present") {
    $existingConfig = Import-ServerConfig "$($env:SystemDrive)\Octopus\OctopusServer.config" "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"
    $existingSqlDbConnectionString = $existingConfig.OctopusStorageExternalDatabaseConnectionString
    $existingWebListenPrefix = $existingConfig.OctopusWebPortalListenPrefixes
  }

  return @{
    Name = $Name;
    Ensure = $existingEnsure;
    State = $existingState;
    DownloadUrl = $existingDownloadUrl;
    WebListenPrefix = $existingWebListenPrefix;
    SqlDbConnectionString = $existingSqlDbConnectionString;
  }
}

function Import-ServerConfig
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string] $Path,
    [Parameter(Mandatory)]
    [string] $OctopusServerExePath
  )

  Write-Verbose "Importing server configuration file from '$Path'"

  if (-not (Test-Path -LiteralPath $Path))
  {
    throw "Config path '$Path' does not exist."
  }

  $file = Get-Item -LiteralPath $Path -ErrorAction Stop
  if ($file -isnot [System.IO.FileInfo])
  {
    throw "Config path '$Path' does not refer to a file."
  }

  if (-not (Test-Path -LiteralPath $OctopusServerExePath))
  {
    throw "Octopus.Server.exe path '$OctopusServerExePath' does not exist."
  }

  $file = Get-Item -LiteralPath $OctopusServerExePath -ErrorAction Stop
  if ($file -isnot [System.IO.FileInfo])
  {
    throw "Octopus.Server.exe path '$OctopusServerExePath ' does not refer to a file."
  }

  $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($OctopusServerExePath).FileVersion
  $octopusServerVersion = New-Object System.Version $fileVersion
  $versionWhereShowConfigurationWasIntroduced = New-Object System.Version 3, 5, 0

  if ($octopusServerVersion -ge $versionWhereShowConfigurationWasIntroduced) {
    $rawConfig = & $OctopusServerExePath show-configuration --format=json-hierarchical --noconsolelogging --console
    #todo: remove this:
    write-verbose $rawConfig
    $config = $rawConfig | ConvertFrom-Json

    $result = [pscustomobject] @{
      OctopusStorageExternalDatabaseConnectionString         = $config.Octopus.Storage.ExternalDatabaseConnectionString
      OctopusWebPortalListenPrefixes                         = $config.Octopus.WebPortal.ListenPrefixes
    }
  }
  else {
    $xml = New-Object xml
    try
    {
      $xml.Load($file.FullName)
    }
    catch
    {
      throw
    }

    $result = [pscustomobject] @{
      OctopusStorageExternalDatabaseConnectionString         = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.Storage.ExternalDatabaseConnectionString"]/text()').Value
      OctopusWebPortalListenPrefixes                         = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.WebPortal.ListenPrefixes"]/text()').Value
    }
  }
  return $result
}

function Set-TargetResource
{
  param (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [ValidateSet("Started", "Stopped")]
    [string]$State = "Started",
    [ValidateNotNullOrEmpty()]
    [string]$DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WebListenPrefix,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SqlDbConnectionString,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OctopusAdminUsername,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OctopusAdminPassword,
    [bool]$upgradeCheck = $true,
    [bool]$upgradeCheckWithStatistics = $true,
    [string]$webAuthenticationMode = 'UsernamePassword',
    [bool]$forceSSL = $false,
    [int]$listenPort = 10943
  )

  if ($Ensure -eq "Absent" -and $State -eq "Started")
  {
    throw "Invalid configuration requested. " + `
          "You have asked for the service to not exist, but also be running at the same time. " +`
          "You probably want 'State = `"Stopped`"."
  }

  $currentResource = (Get-TargetResource -Ensure $Ensure `
                                         -Name $Name `
                                         -State $State `
                                         -DownloadUrl $DownloadUrl `
                                         -WebListenPrefix $WebListenPrefix `
                                         -SqlDbConnectionString $SqlDbConnectionString `
                                         -OctopusAdminUsername $OctopusAdminUsername `
                                         -OctopusAdminPassword $OctopusAdminPassword `
                                         -UpgradeCheck $upgradeCheck `
                                         -UpgradeCheckWithStatistics $upgradeCheckWithStatistics `
                                         -WebAuthenticationMode $webAuthenticationMode `
                                         -ForceSSL $forceSSL `
                                         -ListenPort $listenPort)

  Write-Verbose "Current resource is:"
  $currentResource.Keys | ForEach-Object { write-verbose "* $_ = '$($currentResource.Item($_))'" }

  if ($State -eq "Stopped" -and $currentResource["State"] -eq "Started")
  {
    $serviceName = (Get-ServiceName $Name)
    Write-Verbose "Stopping $serviceName"
    Stop-Service -Name $serviceName -Force
  }

  if ($Ensure -eq "Absent" -and $currentResource["Ensure"] -eq "Present")
  {
    $serviceName = (Get-ServiceName $Name)
    Write-Verbose "Deleting service $serviceName..."
    Invoke-AndAssert { & sc.exe delete $serviceName }

    $otherServices = @(Get-CimInstance win32_service | Where-Object {$_.PathName -like "`"$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe*"})

    if ($otherServices.length -eq 0)
    {
      # Uninstall msi
      Write-Verbose "Uninstalling Octopus..."
      if (-not (Test-Path "$($env:SystemDrive)\Octopus\logs")) { New-Item -type Directory "$($env:SystemDrive)\Octopus\logs" | out-null }
      $msiPath = "$($env:SystemDrive)\Octopus\Octopus-x64.msi"
      $msiLog = "$($env:SystemDrive)\Octopus\logs\Octopus-x64.msi.uninstall.log"
      if (Test-Path $msiPath)
      {
        $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $msiPath /quiet /l*v $msiLog" -Wait -Passthru).ExitCode
        Write-Verbose "MSI uninstaller returned exit code $msiExitCode"
        if ($msiExitCode -ne 0)
        {
          throw "Removal of Octopus Server failed, MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
        }
      }
      else
      {
        throw "Octopus Server cannot be removed, because the MSI could not be found."
      }
    }
    else
    {
      Write-Verbose "Skipping uninstall, as other instances still exist:"
      foreach($otherService in $otherServices)
      {
        Write-Verbose " - $($otherService.Name)"
      }
    }
  }
  elseif ($Ensure -eq "Present" -and $currentResource["Ensure"] -eq "Absent")
  {
    Write-Verbose "Installing Octopus Deploy..."
    New-Instance -name $Name `
                 -downloadUrl $DownloadUrl `
                 -webListenPrefix $WebListenPrefix `
                 -sqlDbConnectionString $SqlDbConnectionString `
                 -OctopusAdminUsername $OctopusAdminUsername `
                 -OctopusAdminPassword $OctopusAdminPassword `
                 -upgradeCheck $upgradeCheck `
                 -upgradeCheckWithStatistics $upgradeCheckWithStatistics `
                 -webAuthenticationMode $webAuthenticationMode `
                 -forceSSL $forceSSL `
                 -listenPort $listenPort
    Write-Verbose "Octopus Deploy installed!"
  }
  elseif ($Ensure -eq "Present" -and $currentResource["DownloadUrl"] -ne $DownloadUrl)
  {
    Write-Verbose "Upgrading Octopus Deploy..."
    $serviceName = (Get-ServiceName $Name)
    Stop-Service -Name $serviceName
    Install-OctopusDeploy $DownloadUrl
    if ($State -eq "Started") {
      Start-Service $serviceName
    }
    Write-Verbose "Octopus Deploy upgraded!"
  }

  if ($State -eq "Started" -and $currentResource["State"] -eq "Stopped")
  {
    $serviceName = (Get-ServiceName $Name)
    Write-Verbose "Starting $serviceName"
    Start-Service -Name $serviceName
  }
}

function Get-ServiceName
{
    param ( [string]$instanceName )

    if ($instanceName -eq "OctopusServer")
    {
        return "OctopusDeploy"
    }
    else
    {
        return "OctopusDeploy: $instanceName"
    }
}

function Install-OctopusDeploy
{
    param (
        [string]$downloadUrl
    )
    Write-Verbose "Beginning installation"

    mkdir "$($env:SystemDrive)\Octopus" -ErrorAction SilentlyContinue

    $msiPath = "$($env:SystemDrive)\Octopus\Octopus-x64.msi"
    if ((Test-Path $msiPath) -eq $true)
    {
        Remove-Item $msiPath -force
    }
    Write-Verbose "Downloading Octopus MSI from $downloadUrl to $msiPath"
    Request-File $downloadUrl $msiPath

    Write-Verbose "Installing MSI..."
    if (-not (Test-Path "$($env:SystemDrive)\Octopus\logs")) { New-Item -type Directory "$($env:SystemDrive)\Octopus\logs" }
    $msiLog = "$($env:SystemDrive)\Octopus\logs\Octopus-x64.msi.log"
    $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /quiet /l*v $msiLog" -Wait -Passthru).ExitCode
    Write-Verbose "MSI installer returned exit code $msiExitCode"
    if ($msiExitCode -ne 0)
    {
        throw "Installation of the MSI failed; MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
    }

    @{ "DownloadUrl" = $downloadUrl } | ConvertTo-Json | set-content "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate"
}

function Request-File
{
    param (
        [string]$url,
        [string]$saveAs
    )

    Write-Verbose "Downloading $url to $saveAs"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls
    $downloader = new-object System.Net.WebClient
    try {
      $downloader.DownloadFile($url, $saveAs)
    }
    catch
    {
       throw $_.Exception.InnerException
    }
}

function Write-Log
{
  param (
    [string] $message
  )

  $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
  Write-Verbose "[$timestamp] $message"
}

function Invoke-AndAssert {
    param ($block)

    & $block | Write-Verbose
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE)
    {
        throw "Command returned exit code $LASTEXITCODE"
    }
}

function New-Instance
{
  param (
    [Parameter(Mandatory=$True)]
    [string]$name,
    [Parameter(Mandatory=$True)]
    [string]$downloadUrl,
    [Parameter(Mandatory=$True)]
    [string]$webListenPrefix,
    [Parameter(Mandatory=$True)]
    [string]$sqlDbConnectionString,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$octopusAdminUsername,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$octopusAdminPassword,
    [bool]$upgradeCheck = $true,
    [bool]$upgradeCheckWithStatistics = $true,
    [string]$webAuthenticationMode = 'UsernamePassword',
    [bool]$forceSSL = $false,
    [int]$listenPort = 10943
  )

  Write-Log "Setting up new instance of Octopus Deploy with name '$name'"
  Install-OctopusDeploy $downloadUrl

  Write-Log "Configure Octopus Deploy"


  Write-Log "Creating Octopus Deploy instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', $name,
    '--config', "$($env:SystemDrive)\Octopus\OctopusServer.config"
  )
  Invoke-OctopusServerCommand $args

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', $name,
    '--home', "$($env:SystemDrive)\Octopus",
    '--upgradeCheck', $upgradeCheck,
    '--upgradeCheckWithStatistics', $upgradeCheckWithStatistics,
    '--webAuthenticationMode', $webAuthenticationMode,
    '--webForceSSL', $forceSSL,
    '--webListenPrefixes', $webListenPrefix,
    '--commsListenPort', $listenPort,
    '--storageConnectionString', $sqlDbConnectionString
  )
  Invoke-OctopusServerCommand $args

  Write-Log "Creating Octopus Deploy database ..."
  $args = @(
    'database',
    '--console',
    '--instance', $name,
    '--create'
  )
  Invoke-OctopusServerCommand $args

  Write-Log "Stopping Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', $name,
    '--stop'
  )
  Invoke-OctopusServerCommand $args

  Write-Log "Creating Admin User for Octopus Deploy instance ..."
  $args = @(
    'admin',
    '--console',
    '--instance', $name,
    '--username', $octopusAdminUsername,
    '--password', $octopusAdminPassword
  )
  Invoke-OctopusServerCommand $args

  Write-Log "Configuring Octopus Deploy instance to use free license ..."
  $args = @(
    'license',
    '--console',
    '--instance', $name,
    '--free'
  )
  Invoke-OctopusServerCommand $args

  Write-Log "Install Octopus Deploy service ..."
  $args = @(
    'service',
    '--console',
    '--instance', $name,
    '--install',
    '--reconfigure',
    '--stop'
  )
  Invoke-OctopusServerCommand $args
}

function Invoke-OctopusServerCommand ($arguments)
{
  $exe = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"
  Write-Log "Executing command '$exe $($arguments -join ' ')'"
  $output = .$exe $arguments

  Write-CommandOutput $output
  if (($null -ne $LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
    Write-Error "Command returned exit code $LASTEXITCODE. Aborting."
    exit 1
  }
  Write-Log "done."
}

function Write-CommandOutput
{
  param (
    [string] $output
  )

  if ($output -eq "") { return }

  Write-Verbose ""
  $output.Trim().Split("`n") | ForEach-Object { Write-Verbose "`t| $($_.Trim())" }
  Write-Verbose ""
}

function Test-TargetResource
{
  param (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [ValidateSet("Started", "Stopped")]
    [string]$State = "Started",
    [ValidateNotNullOrEmpty()]
    [string]$DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WebListenPrefix,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SqlDbConnectionString,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OctopusAdminUsername,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OctopusAdminPassword,
    [bool]$upgradeCheck = $true,
    [bool]$upgradeCheckWithStatistics = $true,
    [string]$webAuthenticationMode = 'UsernamePassword',
    [bool]$forceSSL = $false,
    [int]$listenPort = 10943
  )

  $currentResource = (Get-TargetResource -Ensure $Ensure `
                                         -Name $Name `
                                         -State $State `
                                         -DownloadUrl $DownloadUrl `
                                         -WebListenPrefix $WebListenPrefix `
                                         -SqlDbConnectionString $SqlDbConnectionString `
                                         -OctopusAdminUsername $OctopusAdminUsername `
                                         -OctopusAdminPassword $OctopusAdminPassword `
                                         -UpgradeCheck $upgradeCheck `
                                         -UpgradeCheckWithStatistics $upgradeCheckWithStatistics `
                                         -WebAuthenticationMode $webAuthenticationMode `
                                         -ForceSSL $forceSSL `
                                         -ListenPort $listenPort)

  $match = $currentResource["Ensure"] -eq $Ensure
  Write-Verbose "Ensure: $($currentResource["Ensure"]) vs. $Ensure = $match"
  if (!$match)
  {
    return $false
  }

  $match = $currentResource["State"] -eq $State
  Write-Verbose "State: $($currentResource["State"]) vs. $State = $match"
  if (!$match)
  {
    return $false
  }

  if ($null -ne $currentResource["DownloadUrl"]) {
    $match = $DownloadUrl -eq $currentResource["DownloadUrl"]
    Write-Verbose "Download Url: $($currentResource["DownloadUrl"]) vs. $DownloadUrl = $match"
    if (!$match) {
      return $false
    }
  }

  if ($null -ne $currentResource["WebListenPrefix"]) {
    $match = $WebListenPrefix -eq $currentResource["WebListenPrefix"]
    Write-Verbose "Download Url: $($currentResource["WebListenPrefix"]) vs. $WebListenPrefix = $match"
    if (!$match) {
      return $false
    }
  }

  if ($null -ne $currentResource["SqlDbConnectionString"]) {
    $match = $SqlDbConnectionString -eq $currentResource["SqlDbConnectionString"]
    Write-Verbose "Download Url: $($currentResource["SqlDbConnectionString"]) vs. $SqlDbConnectionString = $match"
    if (!$match) {
        return $false
    }
  }

  return $true
}
