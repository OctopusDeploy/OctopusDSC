# If for whatever reason this doesn't work, check this file:
Start-Transcript -path "C:\OctopusInstallLog.txt" -append

$OFS = "`r`n"
$msiFileName = "Octopus-x64.msi"
$downloadBaseUrl = "https://download.octopusdeploy.com/octopus/"
$downloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer"
$installBasePath = "C:\Install\"
$msiPath = $installBasePath + $msiFileName
$msiLogPath = $installBasePath + $msiFileName + '.log'
$installerLogPath = $installBasePath + 'Install-OctopusDeploy.ps1.log'
$OctopusURI = "http://localhost:$81"
$sqlDbConnectionString="Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"
$octopusAdminUsername="OctoAdmin"
$octopusAdminPassword="Sup3rS3cretPassw0rd!"
$environments = "The-Env"

function Write-Log
{
  param (
    [string] $message
  )

  $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
  Write-Output "[$timestamp] $message"
}

function Execute-Command ($exe, $arguments)
{
  Write-Log "Executing command '$exe $($arguments -join ' ')'"
  $output = .$exe $arguments

  Write-CommandOutput $output
  if (($LASTEXITCODE -ne $null) -and ($LASTEXITCODE -ne 0)) {
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

  Write-Output ""
  $output.Trim().Split("`n") |% { Write-Output "`t| $($_.Trim())" }
  Write-Output ""
}

function Create-InstallLocation
{
  Write-Log "Create Install Location"

  if (!(Test-Path $installBasePath))
  {
    Write-Log "Creating installation folder at '$installBasePath' ..."
    New-Item -ItemType Directory -Path $installBasePath | Out-Null
    Write-Log "done."
  }
  else
  {
    Write-Log "Installation folder at '$installBasePath' already exists."
  }

  Write-Log ""
}

function Install-OctopusDeploy
{
  Write-Log "Install Octopus Deploy"

  Write-Log "Downloading Octopus Deploy installer '$downloadUrl' to '$msiPath' ..."
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls
  (New-Object Net.WebClient).DownloadFile($downloadUrl, $msiPath)
  Write-Log "done."

  Write-Log "Installing via '$msiPath' ..."
  $exe = 'msiexec.exe'
  $args = @(
    '/qn',
    '/i', $msiPath,
    '/l*v', $msiLogPath
  )
  Execute-Command $exe $args

  Write-Log ""
}

function Configure-OctopusDeploy
{
  Write-Log "Configure Octopus Deploy"

  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  $count = 0
  while(!(Test-Path $exe) -and $count -lt 10)
  {
    Write-Log "$exe - not available yet ... waiting 10s ..."
    Start-Sleep -s 10
    $count = $count + 1
  }

  if (!(Test-Path $exe)) {
    Write-Error "Octopus didn't install - waited $($count * 10) seconds for $exe to appear, but it didnt"
    exit 2
  }

  Write-Log "Creating Octopus Deploy instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', 'OctopusServer',
    '--config', 'C:\Octopus\OctopusServer.config'
  )
  Execute-Command $exe $args

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--upgradeCheck', 'True',
    '--upgradeCheckWithStatistics', 'True',
    '--webAuthenticationMode', 'UsernamePassword',
    '--webForceSSL', 'False',
    '--webListenPrefixes', $OctopusURI,
    '--commsListenPort', '10943'
  )
  Execute-Command $exe $args

  Write-Log "Stopping Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', 'OctopusServer',
    '--stop'
  )
  Execute-Command $exe $args

  Write-Log ""
}

function Configure-OctopusDeployDatabase
{
  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--storageConnectionString', $sqlDbConnectionString
  )
  Execute-Command $exe $args

  Write-Log "Creating Octopus Deploy database ..."
  $args = @(
    'database',
    '--console',
    '--instance', 'OctopusServer',
    '--create'
  )
  Execute-Command $exe $args

  Write-Log "Stopping Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', 'OctopusServer',
    '--stop'
  )
  Execute-Command $exe $args

  Write-Log "Creating Admin User for Octopus Deploy instance ..."
  $args = @(
    'admin',
    '--console',
    '--instance', 'OctopusServer',
    '--username', $octopusAdminUserName,
    '--password', $octopusAdminPassword
  )
  Execute-Command $exe $args

  Write-Log "Configuring Octopus Deploy instance to use free license ..."
  $args = @(
    'license',
    '--console',
    '--instance', 'OctopusServer',
    '--free'
  )
  Execute-Command $exe $args

  Write-Log ""
}

function Grant-LocalServiceAccountLoginRights
{
  Write-Log "Granting login rights to 'NT AUTHORITY\SYSTEM'"
  sqlcmd -S "(local)\SQLEXPRESS" -Q "IF NOT EXISTS ( SELECT name FROM master.sys.server_principals WHERE IS_SRVROLEMEMBER ('sysadmin', name) = 1 AND name LIKE 'NT AUTHORITY\SYSTEM' ) EXEC master..sp_addsrvrolemember @loginame = N'NT AUTHORITY\SYSTEM', @rolename = N'sysadmin'"
}

function Run-OctopusDeploy
{
  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  Write-Log "Start Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', 'OctopusServer',
    '--install',
    '--reconfigure',
    '--start'
  )
  Execute-Command $exe $args

  "Run started." | Set-Content "c:\octopus-run.initstate"

  Write-Log ""
}

function Create-APIKey
{
  cd "${env:ProgramFiles}\Octopus Deploy\Octopus"
  Add-Type -Path ".\Newtonsoft.Json.dll"
  Add-Type -Path ".\Octopus.Client.dll"

  #Creating a connection
  $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
  $repository = new-object Octopus.Client.OctopusRepository $endpoint

  $LoginObj = New-Object Octopus.Client.Model.LoginCommand

  #Login with credentials.
  $LoginObj.Username = $octopusAdminUsername
  $LoginObj.Password = $octopusAdminPassword

  $repository.Users.SignIn($LoginObj)

  $UserObj = $repository.Users.GetCurrent()

  $ApiObj = $repository.Users.CreateApiKey($UserObj, "Octopus DSC Testing")

  [environment]::SetEnvironmentVariable("OctopusServerUrl", $OctopusURI, "User")
  [environment]::SetEnvironmentVariable("OctopusServerUrl", $OctopusURI, "Machine")
  [environment]::SetEnvironmentVariable("OctopusApiKey", $ApiObj.ApiKey, "User")
  [environment]::SetEnvironmentVariable("OctopusApiKey", $ApiObj.ApiKey, "Machine")
}

function Create-Environment
{
  param (
    [Parameter(Mandatory=$True)]
    [string]$name
  )

  cd "${env:ProgramFiles}\Octopus Deploy\Octopus"
  Add-Type -Path ".\Newtonsoft.Json.dll"
  Add-Type -Path ".\Octopus.Client.dll"

  #Creating a connection
  $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
  $repository = new-object Octopus.Client.OctopusRepository $endpoint

  $LoginObj = New-Object Octopus.Client.Model.LoginCommand

  #Login with credentials.
  $LoginObj.Username = $octopusAdminUsername
  $LoginObj.Password = $octopusAdminPassword

  $repository.Users.SignIn($LoginObj)
  $EnvironmentObj = New-Object Octopus.Client.Model.EnvironmentResource
  $EnvironmentObj.Name = $name

  $repository.Environments.Create($EnvironmentObj)
}

function Create-Environments
{
  Create-APIKey

  foreach ($environment in $environments)
  {
    Create-Environment -name $environment
  }
}

try
{
  if (-not (Test-Path "c:\temp\octopus-installed.marker")) {
    Write-Log "==============================================="
    Write-Log "Installing Octopus Deploy"
    Write-Log " - downloading from '$downloadUrl'"
    Write-Log "==============================================="

    Write-Log "Installing '$msiFileName'"
    Write-Log ""

    Create-InstallLocation
    Install-OctopusDeploy
    Configure-OctopusDeploy
    Configure-OctopusDeployDatabase
    Grant-LocalServiceAccountLoginRights
    Run-OctopusDeploy
    Create-Environments

    set-content "c:\temp\octopus-installed.marker" ""
  }
}
catch
{
  Write-Log $_
  exit 2
}

