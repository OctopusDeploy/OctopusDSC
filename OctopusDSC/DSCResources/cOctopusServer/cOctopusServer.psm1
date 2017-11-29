$ErrorActionPreference = "Stop"
$installStateFile = "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate"
$octopusServerExePath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"

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
        [PSCredential]$OctopusAdminCredential,
        [bool]$AllowUpgradeCheck = $true,
        [bool]$AllowCollectionOfAnonymousUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$LegacyWebAuthenticationMode = 'Ignore',
        [bool]$ForceSSL = $false,
        [int]$ListenPort = 10943,
        [bool]$AutoLoginEnabled = $false,
        [PSCredential]$OctopusServiceCredential,
        [string]$HomeDirectory,
        [PSCredential]$OctopusMasterKey = [PSCredential]::Empty
    )

    Write-Verbose "Checking if Octopus Server is installed"
    $installLocation = (Get-ItemProperty -path "HKLM:\Software\Octopus\OctopusServer" -ErrorAction SilentlyContinue).InstallLocation
    $present = ($null -ne $installLocation)
    Write-Verbose "Octopus Server present: $present"

    $existingEnsure = if ($present) { "Present" } else { "Absent" }

    $serviceName = (Get-ServiceName $Name)
    Write-Verbose "Checking for Windows Service: $serviceName"
    $serviceInstance = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    $existingState = "Stopped"
    if ($null -ne $serviceInstance) {
        Write-Verbose "Windows service: $($serviceInstance.Status)"
        if ($serviceInstance.Status -eq "Running") {
            $existingState = "Started"
        }

        if ($existingEnsure -eq "Absent") {
            Write-Verbose "Since the Windows Service is still installed, the service is present"
            $existingEnsure = "Present"
        }
    }
    else {
        Write-Verbose "Windows service: Not installed"
        $existingEnsure = "Absent"
    }

    $existingDownloadUrl = $null
    $existingWebListenPrefix = $null
    $existingSqlDbConnectionString = $null
    $existingForceSSL = $null
    $existingOctopusUpgradesAllowChecking = $null
    $existingOctopusUpgradesIncludeStatistics = $null
    $existingListenPort = $null
    $existingOctopusAdminCredential = $null
    $existingAutoLoginEnabled = $null
    $existingOctopusServiceCredential = $null
    $existingHomeDirectory = $null

    if ($existingEnsure -eq "Present") {
        $existingConfig = Import-ServerConfig "$($env:SystemDrive)\Octopus\OctopusServer.config" $Name
        $existingSqlDbConnectionString = $existingConfig.OctopusStorageExternalDatabaseConnectionString
        $existingWebListenPrefix = $existingConfig.OctopusWebPortalListenPrefixes
        $existingForceSSL = $existingConfig.OctopusWebPortalForceSsl
        $existingOctopusUpgradesAllowChecking = $existingConfig.OctopusUpgradesAllowChecking
        $existingOctopusUpgradesIncludeStatistics = $existingConfig.OctopusUpgradesIncludeStatistics
        $existingListenPort = $existingConfig.OctopusCommunicationsServicesPort
        $existingAutoLoginEnabled = $existingConfig.OctopusWebPortalAutoLoginEnabled
        $existingLegacyWebAuthenticationMode = $existingConfig.OctopusWebPortalAuthenticationMode
        $existingHomeDirectory = $existingConfig.OctopusHome
        if (Test-Path $installStateFile) {
            $installState = (Get-Content -Raw -Path $installStateFile | ConvertFrom-Json)
            $existingDownloadUrl = $installState.DownloadUrl
            $pass = $installState.OctopusAdminPassword | ConvertTo-SecureString
      
            if ($installState.OctopusServicePassword -ne "") {
                $svcpass = $installState.OctopusServicePassword | ConvertTo-SecureString 
                $existingOctopusServiceCredential = New-Object System.Management.Automation.PSCredential ($installState.OctopusServiceUsername, $svcpass)
            }
            else {
                $svcpass = ""
                $existingOctopusServiceCredential = [PSCredential]::Empty
            }
            $existingOctopusAdminCredential = New-Object System.Management.Automation.PSCredential ($installState.OctopusAdminUsername, $pass)
        }
    }

    $currentResource = @{
        Name                                      = $Name;
        Ensure                                    = $existingEnsure;
        State                                     = $existingState;
        DownloadUrl                               = $existingDownloadUrl;
        WebListenPrefix                           = $existingWebListenPrefix;
        SqlDbConnectionString                     = $existingSqlDbConnectionString;
        ForceSSL                                  = $existingForceSSL;
        AllowUpgradeCheck                         = $existingOctopusUpgradesAllowChecking;
        AllowCollectionOfAnonymousUsageStatistics = $AllowCollectionOfAnonymousUsageStatistics;
        ListenPort                                = $existingListenPort;
        OctopusAdminCredential                    = $existingOctopusAdminCredential;
        LegacyWebAuthenticationMode               = $existingLegacyWebAuthenticationMode;
        AutoLoginEnabled                          = $existingAutoLoginEnabled;
        OctopusServiceCredential                  = $existingOctopusServiceCredential;
        HomeDirectory                             = $existingHomeDirectory;
    }

    return $currentResource
}

function Import-ServerConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [string] $InstanceName
    )

    Write-Verbose "Importing server configuration file from '$Path'"

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config path '$Path' does not exist."
    }

    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($file -isnot [System.IO.FileInfo]) {
        throw "Config path '$Path' does not refer to a file."
    }

    if (Test-OctopusVersionSupportsShowConfiguration) {
        $rawConfig = & $octopusServerExePath show-configuration --format=json-hierarchical --noconsolelogging --console --instance $InstanceName
        $config = $rawConfig | ConvertFrom-Json

        $result = [pscustomobject] @{
            OctopusStorageExternalDatabaseConnectionString = $config.Octopus.Storage.ExternalDatabaseConnectionString
            OctopusWebPortalListenPrefixes                 = $config.Octopus.WebPortal.ListenPrefixes
            OctopusWebPortalForceSsl                       = [System.Convert]::ToBoolean($config.Octopus.WebPortal.ForceSSL)
            OctopusUpgradesAllowChecking                   = [System.Convert]::ToBoolean($config.Octopus.Upgrades.AllowChecking)
            OctopusUpgradesIncludeStatistics               = [System.Convert]::ToBoolean($config.Octopus.Upgrades.IncludeStatistics)
            OctopusCommunicationsServicesPort              = $config.Octopus.Communications.ServicesPort
            OctopusWebPortalAuthenticationMode             = "Ignore"
            OctopusWebPortalAutoLoginEnabled               = [System.Convert]::ToBoolean($config.Octopus.WebPortal.AutoLoginEnabled)
            OctopusHomeDirectory                           = $config.Octopus.Home
        }
    }
    else {
        $xml = New-Object xml
        try {
            $xml.Load($file.FullName)
        }
        catch {
            throw
        }

        $result = [pscustomobject] @{
            OctopusStorageExternalDatabaseConnectionString = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.Storage.ExternalDatabaseConnectionString"]/text()').Value
            OctopusWebPortalListenPrefixes                 = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.WebPortal.ListenPrefixes"]/text()').Value
            OctopusWebPortalForceSsl                       = [System.Convert]::ToBoolean($xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.WebPortal.ForceSsl"]/text()').Value)
            OctopusUpgradesAllowChecking                   = [System.Convert]::ToBoolean($xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.Upgrades.AllowChecking"]/text()').Value)
            OctopusUpgradesIncludeStatistics               = [System.Convert]::ToBoolean($xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.Upgrades.IncludeStatistics"]/text()').Value)
            OctopusCommunicationsServicesport              = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.Communications.ServicesPort"]/text()').Value
            OctopusWebPortalAuthenticationMode             = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.WebPortal.AuthenticationMode"]/text()').Value
            OctopusWebPortalAutoLoginEnabled               = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.WebPortal.AutoLoginEnabled"]/text()').Value
            OctopusHomeDirectory                           = $xml.SelectSingleNode('/octopus-settings/set[@key="Octopus.Home"]/text()').Value
        }

        if ($result.OctopusWebPortalAuthenticationMode -eq '0') { $result.OctopusWebPortalAuthenticationMode = 'UsernamePassword' }
        elseif ($result.OctopusWebPortalAuthenticationMode -eq '1') { $result.OctopusWebPortalAuthenticationMode = 'Domain' }
    }
    return $result
}

function Test-OctopusVersionSupportsAutoLoginEnabled {
    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 5, 0)
}

function Test-OctopusVersionSupportsShowConfiguration {
    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 5, 0)
}

function Test-OctopusVersionSupportsHomeDirectoryDuringCreateInstance {
    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 16, 4)
}

Function Test-OctopusVersionRequiresDatabaseBeforeConfigure {
    return Test-OctopusVersionNewerThan (New-Object System.Version 4, 0, 0)
}

function Test-OctopusVersionNewerThan($targetVersion) {
    if (-not (Test-Path -LiteralPath $octopusServerExePath)) {
        throw "Octopus.Server.exe path '$octopusServerExePath' does not exist."
    }

    $exeFile = Get-Item -LiteralPath $octopusServerExePath -ErrorAction Stop
    if ($exeFile -isnot [System.IO.FileInfo]) {
        throw "Octopus.Server.exe path '$octopusServerExePath ' does not refer to a file."
    }

    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($octopusServerExePath).FileVersion
    $octopusServerVersion = New-Object System.Version $fileVersion

    return ($octopusServerVersion -ge $targetVersion)
}

function Set-TargetResource {
    #The Write-Verbose calls are in other methods
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
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
        [PSCredential]$OctopusAdminCredential,
        [bool]$AllowUpgradeCheck = $true,
        [bool]$AllowCollectionOfAnonymousUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$LegacyWebAuthenticationMode = 'Ignore',
        [bool]$ForceSSL = $false,
        [int]$ListenPort = 10943,
        [bool]$AutoLoginEnabled = $false,
        [PSCredential]$OctopusServiceCredential,
        [string]$HomeDirectory,
        [PSCredential]$OctopusMasterKey = [PSCredential]::Empty
    )

    $currentResource = (Get-TargetResource -Ensure $Ensure `
            -Name $Name `
            -State $State `
            -DownloadUrl $DownloadUrl `
            -WebListenPrefix $WebListenPrefix `
            -SqlDbConnectionString $SqlDbConnectionString `
            -OctopusAdminCredential $OctopusAdminCredential `
            -AllowUpgradeCheck $AllowUpgradeCheck `
            -AllowCollectionOfAnonymousUsageStatistics $AllowCollectionOfAnonymousUsageStatistics `
            -LegacyWebAuthenticationMode $LegacyWebAuthenticationMode `
            -ForceSSL $ForceSSL `
            -ListenPort $ListenPort `
            -AutoLoginEnabled $AutoLoginEnabled `
            -OctopusServiceCredential $OctopusServiceCredential `
            -HomeDirectory $HomeDirectory `
            -OctopusMasterKey $OctopusMasterKey)

    $params = Get-ODSCParameter $MyInvocation.MyCommand.Parameters
    Test-RequestedConfiguration $currentResource $params

    if ($State -eq "Stopped" -and $currentResource["State"] -eq "Started") {
        Stop-OctopusDeployService $Name
    }

    if ($Ensure -eq "Absent" -and $currentResource["Ensure"] -eq "Present") {
        Uninstall-OctopusDeploy $Name
    }
    elseif ($Ensure -eq "Present" -and $currentResource["Ensure"] -eq "Absent") {
        Install-OctopusDeploy -name $Name `
            -downloadUrl $DownloadUrl `
            -webListenPrefix $WebListenPrefix `
            -sqlDbConnectionString $SqlDbConnectionString `
            -OctopusAdminCredential $OctopusAdminCredential `
            -allowUpgradeCheck $AllowUpgradeCheck `
            -allowCollectionOfAnonymousUsageStatistics $AllowCollectionOfAnonymousUsageStatistics `
            -legacyWebAuthenticationMode $LegacyWebAuthenticationMode `
            -forceSSL $ForceSSL `
            -listenPort $ListenPort `
            -autoLoginEnabled $AutoLoginEnabled `
            -homeDirectory $HomeDirectory `
            -octopusServiceCredential $OctopusServiceCredential `
            -OctopusMasterKey $OctopusMasterKey
    }
    else {
        if ($Ensure -eq "Present" -and $currentResource["DownloadUrl"] -ne $DownloadUrl) {
            Update-OctopusDeploy -name $Name `
                -downloadUrl $DownloadUrl `
                -state $State `
                -url ($webListenPrefix -split ';')[0]
        }
        if (Test-ReconfigurationRequired $currentResource $params) {
            Set-OctopusDeployConfiguration -name $Name `
                -webListenPrefix $WebListenPrefix `
                -allowUpgradeCheck $AllowUpgradeCheck `
                -allowCollectionOfAnonymousUsageStatistics $AllowCollectionOfAnonymousUsageStatistics `
                -legacyWebAuthenticationMode $LegacyWebAuthenticationMode `
                -forceSSL $ForceSSL `
                -listenPort $ListenPort `
                -autoLoginEnabled $AutoLoginEnabled `
                -homeDirectory $HomeDirectory `
                -octopusServiceCredential $OctopusServiceCredential `
                -OctopusMasterKey $OctopusMasterKey
        }
    }

    if ($State -eq "Started" -and $currentResource["State"] -eq "Stopped") {
        Start-OctopusDeployService -name $Name -url ($webListenPrefix -split ';')[0]
    }
}

function Test-RequestedConfiguration($currentState, $desiredState) {
    if ($desiredState.Item('Ensure') -eq "Absent" -and $desiredState.Item('State') -eq "Started") {
        throw "Invalid configuration requested. " + `
            "You have asked for the service to not exist, but also be running at the same time. " + `
            "You probably want 'State = `"Stopped`"."
    }

    if ($currentState.Item['Ensure'] -eq "Present") {
        if (Test-OctopusVersionSupportsShowConfiguration) {
            if ($desiredState.Item('LegacyWebAuthenticationMode') -ne 'Ignore') {
                #todo: add note to use new auth resources
                throw "LegacyWebAuthenticationMode is only supported for Octopus versions older than 3.5.0."
            }
        }
        else {
            if ($desiredState.Item('LegacyWebAuthenticationMode') -eq 'Ignore') {
                throw "LegacyWebAuthenticationMode = 'ignore' is only supported from Octopus 3.5.0."
            }
        }
    }
}

function Set-OctopusDeployConfiguration {
    param (
        [Parameter(Mandatory = $True)]
        [string]$name,
        [Parameter(Mandatory = $True)]
        [string]$webListenPrefix,
        [Parameter(Mandatory)]
        [bool]$allowUpgradeCheck = $true,
        [bool]$allowCollectionOfAnonymousUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$legacyWebAuthenticationMode = 'Ignore',
        [bool]$forceSSL = $false,
        [int]$listenPort = 10943,
        [bool]$autoLoginEnabled = $false,
        [string]$homeDirectory = $null,
        [PSCredential]$OctopusServiceCredential,
        [PSCredential]$OctopusMasterKey
    )

    Write-Log "Configuring Octopus Deploy instance ..."
    $args = @(
        'configure',
        '--console',
        '--instance', $name,
        '--upgradeCheck', $allowUpgradeCheck,
        '--upgradeCheckWithStatistics', $allowCollectionOfAnonymousUsageStatistics,
        '--webForceSSL', $forceSSL,
        '--webListenPrefixes', $webListenPrefix,
        '--commsListenPort', $listenPort
    )
    if (($homeDirectory -ne "") -and ($null -ne $homeDirectory)) {
        $args += @('--home', $homeDirectory)
    }
    if (Test-OctopusVersionSupportsAutoLoginEnabled) {
        $args += @('--autoLoginEnabled', $autoLoginEnabled)
    }
    else {
        if (-not ($autoLoginEnabled)) {
            throw "AutoLoginEnabled is only supported from Octopus 3.5.0."
        }
    }

    if (Test-OctopusVersionSupportsShowConfiguration) {
        if ($legacyWebAuthenticationMode -ne 'Ignore') {
            #todo: add note to use new auth resources
            throw "LegacyWebAuthenticationMode is only supported for Octopus versions older than 3.5.0."
        }
    }
    else {
        if ($legacyWebAuthenticationMode -eq 'Ignore') {
            throw "LegacyWebAuthenticationMode = 'ignore' is only supported from Octopus 3.5.0."
        }
        $args += @('--webAuthenticationMode', $legacyWebAuthenticationMode)
    }

    Invoke-OctopusServerCommand $args

    if ($octopusServiceCredential) {
        $args += @("--username", $octopusServiceCredential.UserName
            "--password", $octopusServiceCredential.Password | ConvertFrom-SecureString)

        Update-InstallState "OctopusServiceUsername" $octopusServiceCredential.UserName
        Update-InstallState "OctopusServicePassword" ($octopusServiceCredential.Password | ConvertFrom-SecureString)
        Invoke-OctopusServerCommand $args 
    }
    else {
        Update-InstallState "OctopusServiceUsername" $null
        Update-InstallState "OctopusServicePassword" $null
    }

}

function Test-ReconfigurationRequired($currentState, $desiredState) {
    $reconfigurableProperties = @('ListenPort', 'WebListenPrefix', 'ForceSSL', 'AllowCollectionOfAnonymousUsageStatistics', 'AllowUpgradeCheck', 'LegacyWebAuthenticationMode', 'Home')
    foreach ($property in $reconfigurableProperties) {
        if ($currentState.Item($property) -ne ($desiredState.Item($property))) {
            return $true
        }
    }
    return $false
}

function Uninstall-OctopusDeploy($name) {
    $services = @(Get-CimInstance win32_service | Where-Object {$_.PathName -like "`"$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe*"})
    Write-Verbose "Found $($services.length) instance(s)"
    Write-Log "Uninstalling Octopus Deploy service ..."
    $args = @(
        'service',
        '--stop',
        '--uninstall',
        '--console',
        '--instance', $name
    )
    Invoke-OctopusServerCommand $args

    Write-Log "Deleting Octopus Deploy instance ..."
    $args = @(
        'delete-instance',
        '--console',
        '--instance', $name
    )
    Invoke-OctopusServerCommand $args

    if ($services.length -eq 1) {
        # Uninstall msi
        Write-Verbose "Uninstalling Octopus..."
        if (-not (Test-Path "$($env:SystemDrive)\Octopus\logs")) { New-Item -type Directory "$($env:SystemDrive)\Octopus\logs" | out-null }
        $msiPath = "$($env:SystemDrive)\Octopus\Octopus-x64.msi"
        $msiLog = "$($env:SystemDrive)\Octopus\logs\Octopus-x64.msi.uninstall.log"
        if (Test-Path $msiPath) {
            $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $msiPath /quiet /l*v $msiLog" -Wait -Passthru).ExitCode
            Write-Verbose "MSI uninstaller returned exit code $msiExitCode"
            if ($msiExitCode -ne 0) {
                throw "Removal of Octopus Server failed, MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
            }
        }
        else {
            throw "Octopus Server cannot be removed, because the MSI could not be found."
        }
    }
    else {
        Write-Verbose "Skipping uninstall, as other instances still exist:"
        foreach ($otherService in $otherServices) {
            Write-Verbose " - $($otherService.Name)"
        }
    }
}

function Update-OctopusDeploy($name, $downloadUrl, $state, $url) {
    Write-Verbose "Upgrading Octopus Deploy..."
    Stop-OctopusDeployService -name $name
    Install-MSI $downloadUrl
    if ($state -eq "Started") {
        Start-OctopusDeployService -name $name -url $url
    }
    Write-Verbose "Octopus Deploy upgraded!"
}

function Start-OctopusDeployService($name, $url) {
    Write-Log "Starting Octopus Deploy instance ..."
    $args = @(
        'service',
        '--start',
        '--console',
        '--instance', $name
    )
    Invoke-OctopusServerCommand $args

    $timeout = new-timespan -Minutes 5
    $sw = [diagnostics.stopwatch]::StartNew()
    while (($sw.elapsed -lt $timeout) -and (-not (Test-OctopusDeployServerResponding $url))) {
        Write-Verbose "$(date) Waiting until server completes startup"
        start-sleep 5
    }
}

function Test-OctopusDeployServerResponding($url) {
    try {
        Write-Verbose "Checking if $url/api is responding..."
        Invoke-WebRequest "$url/api" -UseBasicParsing | Out-Null
        return $true
    }
    catch {
        write-verbose "Server returned error $($_)"
        return $false
    }
}

function Stop-OctopusDeployService($name) {
    Write-Log "Stopping Octopus Deploy instance ..."
    $args = @(
        'service',
        '--stop',
        '--console',
        '--instance', $name
    )
    Invoke-OctopusServerCommand $args
}

function Get-ServiceName {
    param ( [string]$instanceName )

    if ($instanceName -eq "OctopusServer") {
        return "OctopusDeploy"
    }
    else {
        return "OctopusDeploy: $instanceName"
    }
}

function Install-MSI {
    param (
        [string]$downloadUrl
    )
    Write-Verbose "Beginning installation"

    mkdir "$($env:SystemDrive)\Octopus" -ErrorAction SilentlyContinue

    $msiPath = "$($env:SystemDrive)\Octopus\Octopus-x64.msi"
    if ((Test-Path $msiPath) -eq $true) {
        Remove-Item $msiPath -force
    }
    Request-File $downloadUrl $msiPath

    Write-Verbose "Installing MSI..."
    if (-not (Test-Path "$($env:SystemDrive)\Octopus\logs")) { New-Item -type Directory "$($env:SystemDrive)\Octopus\logs" }
    $msiLog = "$($env:SystemDrive)\Octopus\logs\Octopus-x64.msi.log"
    $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /quiet /l*v $msiLog" -Wait -Passthru).ExitCode
    Write-Verbose "MSI installer returned exit code $msiExitCode"
    if ($msiExitCode -ne 0) {
        throw "Installation of the MSI failed; MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
    }

    Update-InstallState "DownloadUrl" $downloadUrl
}

function Update-InstallState {
    param (
        [string]$key,
        [string]$value
    )

    $currentInstallState = @{}
    if (Test-Path $installStateFile) {
        $fileContent = (Get-Content -Raw -Path $installStateFile | ConvertFrom-Json)
        $fileContent.psobject.properties | ForEach-Object { $currentInstallState[$_.Name] = $_.Value }
    }

    $currentInstallState.Set_Item($key, $value)

    $currentInstallState | ConvertTo-Json | set-content $installStateFile
}

function Request-File {
    param (
        [string]$url,
        [string]$saveAs
    )

    $retry = $true
    $retryCount = 0
    $maxRetries = 5
    while ($retry) {
        Write-Verbose "Downloading $url to $saveAs"
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12, [System.Net.SecurityProtocolType]::Tls11, [System.Net.SecurityProtocolType]::Tls
        $downloader = new-object System.Net.WebClient
        try {
            $downloader.DownloadFile($url, $saveAs)
            $retry = $false
        }
        catch {
            Write-Verbose "Failed to download $url"
            Write-Verbose "Got exception '$($_.Exception.InnerException.Message)'."
            Write-Verbose "Retrying up to $maxRetries times."
            if (($_.Exception.InnerException.Message -notlike "The request was aborted: Could not create SSL/TLS secure channel.") -or ($retryCount -gt $maxRetries)) {
                throw $_.Exception.InnerException
            }
            $retryCount = $retryCount + 1
            Start-Sleep -Seconds 1
        }
    }
}

function Write-Log {
    param (
        [string] $message
    )

    $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
    Write-Verbose "[$timestamp] $message"
}

function Invoke-AndAssert {
    param ($block)

    & $block | Write-Verbose
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "Command returned exit code $LASTEXITCODE"
    }
}

function Get-RegistryValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )
    try {
        return Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop
    }
    catch {
        return ""
    }
}

function Install-OctopusDeploy {
    param (
        [Parameter(Mandatory = $True)]
        [string]$name,
        [Parameter(Mandatory = $True)]
        [string]$downloadUrl,
        [Parameter(Mandatory = $True)]
        [string]$webListenPrefix,
        [Parameter(Mandatory = $True)]
        [string]$sqlDbConnectionString,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$octopusAdminCredential,
        [bool]$allowUpgradeCheck = $true,
        [bool]$allowCollectionOfAnonymousUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$legacyWebAuthenticationMode = 'Ignore', 
        [bool]$forceSSL = $false,
        [int]$listenPort = 10943,
        [bool]$autoLoginEnabled = $false,
        [string]$homeDirectory = $null,
        [PSCredential]$octopusServiceCredential,
        [PSCredential]$OctopusMasterKey
    )

    Write-Verbose "Installing Octopus Deploy..."

    Write-Log "Checking to make sure .net 4.5.1+ is installed"
    $dotnetVersion = Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
    if (($dotnetVersion -eq "") -or ([int]$dotnetVersion -lt 378675)) {
        throw "Octopus Server requires .NET 4.5.1. Please install it before attempting to install Octopus Server."
    }

    $extractedUserName = $octopusAdminCredential.GetNetworkCredential().UserName
    $extractedPassword = $octopusAdminCredential.GetNetworkCredential().Password

    # check if we're upgrading an existing instance
    $isUpgrade = (Test-Path -LiteralPath $OctopusServerExePath)

    # check if we're joining a cluster, or joining to an existing Database
    $isClusterJoin = ($OctopusMasterKey -ne [pscredential]::Empty)

    Write-Log "Setting up new instance of Octopus Deploy with name '$name'"
    Install-MSI $downloadUrl

    Write-Log "Creating Octopus Deploy instance ..."
    $args = @(
        'create-instance',
        '--console',
        '--instance', $name,
        '--config', "$($env:SystemDrive)\Octopus\OctopusServer.config"
    )
    if (Test-OctopusVersionSupportsHomeDirectoryDuringCreateInstance) {
        if (($homeDirectory -ne "") -and ($null -ne $homeDirectory)) {
            $args += @('--home', $homeDirectory)
        }
        else {
            $args += @('--home', "$($env:SystemDrive)\Octopus")
        }
    }
    Invoke-OctopusServerCommand $args

    Write-Log "Configuring Octopus Deploy instance ..."

    if ($OctopusServiceCredential) {
        $databaseusername = $OctopusServiceCredential.UserName 
    }
    else {
        $databaseusername = "NT AUTHORITY\SYSTEM"
    }

    $args = @(
        'configure',
        '--console',
        '--instance', $name,
        '--upgradeCheck', $allowUpgradeCheck,
        '--upgradeCheckWithStatistics', $allowCollectionOfAnonymousUsageStatistics,
        '--webForceSSL', $forceSSL,
        '--webListenPrefixes', $webListenPrefix,
        '--commsListenPort', $listenPort
    )

    if (Test-OctopusVersionRequiresDatabaseBeforeConfigure) {
        if ($isUpgrade -eq $true) {
            Write-Log "Upgrading Octopus Deploy database for v4"
            $action = '--upgrade'
        }
        else {
            Write-Log "Creating Octopus Deploy database for v4"
            $action = '--create'
        }
    
        $dbargs = @(
            'database',
            '--instance', $name,
            '--connectionstring', $sqlDbConnectionString,
            $action,
            '--grant', $databaseusername
        )

        if ($isClusterJoin) {
            $dbargs += @("--masterKey", $OctopusMasterKey.GetNetworkCredential().Password)
        }

        Invoke-OctopusServerCommand $dbargs

    }
    else {
        $args += @("--StorageConnectionString", $sqlDbConnectionString)

        if ($isClusterJoin) {
            $args += @("--masterKey", $OctopusMasterKey.GetNetworkCredential().Password)
        }

    }


    if (-not (Test-OctopusVersionSupportsHomeDirectoryDuringCreateInstance)) {
        if (($homeDirectory -ne "") -and ($null -ne $homeDirectory)) {
            $args += @('--home', $homeDirectory)
        }
        else {
            $args += @('--home', "$($env:SystemDrive)\Octopus")
        }
    }

    if (Test-OctopusVersionSupportsAutoLoginEnabled) {
        $args += @('--autoLoginEnabled', $autoLoginEnabled)
    }
    elseif ($autoLoginEnabled) {
        throw "AutoLoginEnabled is only supported from Octopus 3.5.0."
    }

    if (Test-OctopusVersionSupportsShowConfiguration) {
        if ($legacyWebAuthenticationMode -ne 'Ignore') {
            #todo: add note to use new auth resources
            throw "LegacyWebAuthenticationMode is only supported for Octopus versions older than 3.5.0."
        }
    }
    else {
        if ($legacyWebAuthenticationMode -eq 'Ignore') {
            throw "LegacyWebAuthenticationMode = 'ignore' is only supported from Octopus 3.5.0."
        }
        $args += @('--webAuthenticationMode', $legacyWebAuthenticationMode)
    }

    Invoke-OctopusServerCommand $args

    if (-not (Test-OctopusVersionNewerThan (New-Object System.Version 4, 0, 0))) {
        Write-Log "Creating Octopus Deploy database for v3..."
        $args = @(
            'database',
            '--console',
            '--instance', $name,
            '--create'
        )

        if ($isClusterJoin) {
            $args += @("--masterKey", $OctopusMasterKey.GetNetworkCredential().Password)
        }

        Invoke-OctopusServerCommand $args
    }

    Write-Log "Stopping Octopus Deploy instance ..."
    $args = @(
        'service',
        '--console',
        '--instance', $name,
        '--stop'
    )
    Invoke-OctopusServerCommand $args

    if (-not $isClusterJoin) {
      # we do not need licence or admin user for Cluster Join operations
        Write-Log "Creating Admin User for Octopus Deploy instance ..."
        $args = @(
            'admin',
            '--console',
            '--instance', $name,
            '--username', $extractedUsername,
            '--password', $extractedPassword
        )

  
        Invoke-OctopusServerCommand $args
        Update-InstallState "OctopusAdminUsername" $extractedUsername
        Update-InstallState "OctopusAdminPassword" ($OctopusAdminCredential.Password | ConvertFrom-SecureString)
  

        Write-Log "Configuring Octopus Deploy instance to use free license ..."
        $args = @(
            'license',
            '--console',
            '--instance', $name,
            '--free'
        )
        Invoke-OctopusServerCommand $args

    }
  
    Write-Log "Install Octopus Deploy service ..."
    $args = @(
        'service',
        '--console',
        '--instance', $name,
        '--install',
        '--reconfigure',
        '--stop'
    )

    if ($octopusServiceCredential) {
        Write-Log "Adding Service identity to installation command"

        $args += @("--username", $octopusServiceCredential.UserName
            "--password", $octopusServiceCredential.GetNetworkCredential().Password )

        Write-Log "Adding Service identity to installation command"

        Update-InstallState "OctopusServiceUsername" $octopusServiceCredential.UserName
        Update-InstallState "OctopusServicePassword" ($octopusServiceCredential.Password | ConvertFrom-SecureString)
    }
    else {
        Update-InstallState "OctopusServiceUsername" $null
        Update-InstallState "OctopusServicePassword" $null
    }

    Invoke-OctopusServerCommand $args

    Write-Verbose "Octopus Deploy installed!"
}

Function Invoke-OctopusServerCommand ($arguments) {
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

function Write-CommandOutput {
    param (
        [string] $output
    )

    if ($output -eq "") { return }

    Write-Verbose ""
    #this isn't quite working
    foreach ($line in $output.Trim().Split("`n")) {
        Write-Verbose $line
    }
    Write-Verbose ""
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
        [PSCredential]$OctopusAdminCredential,
        [bool]$AllowUpgradeCheck = $true,
        [bool]$AllowCollectionOfAnonymousUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$LegacyWebAuthenticationMode = 'Ignore',
        [bool]$ForceSSL = $false,
        [int]$ListenPort = 10943,
        [bool]$AutoLoginEnabled = $false,
        [PSCredential]$OctopusServiceCredential,
        [string]$HomeDirectory,
        [PSCredential]$OctopusMasterKey = [PSCredential]::Empty
    )

    $currentResource = (Get-TargetResource -Ensure $Ensure `
            -Name $Name `
            -State $State `
            -DownloadUrl $DownloadUrl `
            -WebListenPrefix $WebListenPrefix `
            -SqlDbConnectionString $SqlDbConnectionString `
            -OctopusAdminCredential $OctopusAdminCredential `
            -AllowUpgradeCheck $AllowUpgradeCheck `
            -AllowCollectionOfAnonymousUsageStatistics $AllowCollectionOfAnonymousUsageStatistics `
            -LegacyWebAuthenticationMode $LegacyWebAuthenticationMode `
            -ForceSSL $ForceSSL `
            -ListenPort $ListenPort `
            -AutoLoginEnabled $AutoLoginEnabled `
            -OctopusServiceCredential $OctopusServiceCredential `
            -HomeDirectory $HomeDirectory)

    $params = Get-ODSCParameter $MyInvocation.MyCommand.Parameters

    $currentConfigurationMatchesRequestedConfiguration = $true
    foreach ($key in $currentResource.Keys) {
        $currentValue = $currentResource.Item($key)
        $requestedValue = $params.Item($key)
        if ($key -eq "OctopusAdminCredential") {
            if ($null -ne $currentValue) {
                $currentUsername = $currentValue.GetNetworkCredential().UserName
                $currentPassword = $currentValue.GetNetworkCredential().Password
            }
            else {
                $currentUserName = ""
                $currentPassword = ""
            }

            $requestedUsername = $requestedValue.GetNetworkCredential().UserName
            $requestedPassword = $requestedValue.GetNetworkCredential().Password      

            if ($currentPassword -ne $requestedPassword -or $currentUsername -ne $requestedUserName) {
                Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '********' mismatched the specified value '********'"
                $currentConfigurationMatchesRequestedConfiguration = $false
            }
            else {
                Write-Verbose "Configuration parameter '$key' matches the requested value '********'"
            }


        }
        elseif ($currentValue -ne $requestedValue) {
            Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '$currentValue' mismatched the specified value '$requestedValue'"
            $currentConfigurationMatchesRequestedConfiguration = $false
        }
        else {
            Write-Verbose "Configuration parameter '$key' matches the requested value '$requestedValue'"
        }
    }

    return $currentConfigurationMatchesRequestedConfiguration
}

function Get-ODSCParameter($parameters) {
    # unfortunately $PSBoundParameters doesn't contain parameters that weren't supplied (because the default value was okay)
    # credit to https://www.briantist.com/how-to/splatting-psboundparameters-default-values-optional-parameters/
    $params = @{}
    foreach ($h in $parameters.GetEnumerator()) {
        $key = $h.Key
        $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
        if ($null -ne $var) {
            $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
            $params[$key] = $val
        }
    }
    return $params
}