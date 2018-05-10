$ErrorActionPreference = "Stop"
$octopusServerExePath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"
$script:instancecontext = ''  # a global to hold the name of the current instance's context

# dot-source the helper file (cannot load as a module due to scope considerations)
. (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'OctopusDSCHelpers.ps1')

function Resolve-Error
{
    param (
        $ErrorRecord=$Error[0]
    )
    
    $separator = "*********************************************************"
    write-verbose ("`r`n{0}`r`nUnhandled exception: $ErrorRecord`r`n{0}`r`n$($ErrorRecord.ScriptStackTrace)`r`n{0}`r`n" -f $separator)
}

function Get-TargetResource {
    [OutputType([Hashtable])]
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [Parameter(Mandatory)]
        [string]$Name,
        [ValidateSet("Started", "Stopped", "Installed")]
        [string]$State = "Started",
        [string]$DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
        [string]$WebListenPrefix,
        [string]$SqlDbConnectionString,
        [PSCredential]$OctopusAdminCredential,
        [bool]$AllowUpgradeCheck = $true,
        [bool]$AllowCollectionOfUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$LegacyWebAuthenticationMode = 'Ignore',
        [bool]$ForceSSL = $false,
        [bool]$HSTSEnabled = $false,
        [Int64]$HSTSMaxAge = 3600, # 1 hour
        [int]$ListenPort = 10943,
        [Nullable[bool]]$AutoLoginEnabled = $null,
        [PSCredential]$OctopusServiceCredential,
        [string]$HomeDirectory = "$($env:SystemDrive)\Octopus",
        [string]$ServerLogsDirectory = "$HomeDirectory\Logs",
        [string]$ServerMetricsDirectory = "$HomeDirectory\Logs",
        [PSCredential]$OctopusMasterKey = [PSCredential]::Empty,
        [string]$LicenseKey = $null,
        [bool]$GrantDatabasePermissions = $true,
        [PSCredential]$OctopusBuiltInWorkerCredential = [PSCredential]::Empty,
        [string]$PackagesDirectory = "$HomeDirectory\Packages",
        [string]$ArtifactsDirectory = "$HomeDirectory\Artifacts",
        [string]$TaskLogsDirectory = "$HomeDirectory\TaskLogs",
        [bool]$LogTaskMetrics = $false,
        [bool]$LogRequestMetrics = $false
    )

    try {

        Test-ParameterSet -Ensure $Ensure `
                          -Name $Name `
                          -State $State `
                          -DownloadUrl $DownloadUrl `
                          -WebListenPrefix $WebListenPrefix `
                          -SqlDbConnectionString $SqlDbConnectionString `
                          -OctopusAdminCredential $OctopusAdminCredential

        $script:instancecontext = $Name

        $serviceName = (Get-ServiceName $Name)
        Write-Verbose "Checking for Windows Service: $serviceName"
        $serviceInstance = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        $existingState = "Stopped"
        if ($null -ne $serviceInstance) {
            Write-Verbose "Windows service: $($serviceInstance.Status)"
            $existingEnsure = "Present"
            if ($serviceInstance.Status -eq "Running") {
                $existingState = "Started"
            }
        }
        else {
            Write-Verbose "Windows service: Not installed"

            Write-Verbose "Checking for Octopus Server registry key"
            $installLocation = (Get-ItemProperty -path "HKLM:\Software\Octopus\OctopusServer" -ErrorAction SilentlyContinue).InstallLocation
            $regKeyPresent = ($null -ne $installLocation)
            if ($regKeyPresent) {
                Write-Verbose "Octopus Server registry key: Found"
                $existingState = 'Installed'
                $existingEnsure = "Present"
            } else {
                Write-Verbose "Octopus Server registry key: Not found"
                $existingEnsure = "Absent"
            }
        }

        $existingDownloadUrl = $null
        $existingWebListenPrefix = $null
        $existingSqlDbConnectionString = $null
        $existingForceSSL = $null
        $existingHSTSEnabled = $null
        $existingHSTSMaxAge = $null
        $existingOctopusUpgradesAllowChecking = $null
        $existingOctopusUpgradesIncludeStatistics = $null
        $existingListenPort = $null
        $existingOctopusAdminCredential = [PSCredential]::Empty
        $existingAutoLoginEnabled = $null
        $existingOctopusServiceCredential = [PSCredential]::Empty
        $existingOctopusBuiltInWorkerCredential = [PSCredential]::Empty
        $existingHomeDirectory = $null
        $existingServerLogsDirectory = $null
        $existingServerMetricsDirectory = $null
        $existingPackagesDirectory = $null
        $existingArtifactsDirectory = $null
        $existingTaskLogsDirectory = $null
        $existingLogTaskMetrics = $null
        $existingLogRequestMetrics = $null

        if ($existingEnsure -eq "Present") {

            $existingDownloadUrl = Get-InstallStateValue 'DownloadUrl' -global

            if ($existingState -ne "Installed") {
                if(Test-Path "$($env:SystemDrive)\Octopus\OctopusServer-$Name.config")
                {
                    $configPath = "$($env:SystemDrive)\Octopus\OctopusServer-$Name.config"
                }
                else
                {
                    $configPath = "$($env:SystemDrive)\Octopus\OctopusServer.config"
                }
                $existingConfig = Import-ServerConfig $configPath $Name
                $existingSqlDbConnectionString = $existingConfig.OctopusStorageExternalDatabaseConnectionString
                $existingWebListenPrefix = $existingConfig.OctopusWebPortalListenPrefixes
                $existingForceSSL = $existingConfig.OctopusWebPortalForceSsl
                $existingHSTSEnabled = $existingConfig.OctopusWebPortalHstsEnabled
                $existingHSTSMaxAge = $existingConfig.OctopusWebPortalHstsMaxAge
                $existingOctopusUpgradesAllowChecking = $existingConfig.OctopusUpgradesAllowChecking
                $existingOctopusUpgradesIncludeStatistics = $existingConfig.OctopusUpgradesIncludeStatistics
                $existingListenPort = $existingConfig.OctopusCommunicationsServicesPort
                $existingAutoLoginEnabled = $existingConfig.OctopusWebPortalAutoLoginEnabled
                $existingLegacyWebAuthenticationMode = $existingConfig.OctopusWebPortalAuthenticationMode
                $existingHomeDirectory = $existingConfig.OctopusHomeDirectory
                $existingServerLogsDirectory = $existingConfig.OctopusFoldersServerLogsDirectory
                $existingServerMetricsDirectory = $existingConfig.OctopusFoldersServerMetricsDirectory
                if ($existingConfig.OctopusLicenseKey -eq "<unknown>") {
                    $existingLicenseKey = $LicenseKey #if we weren't able to determine the existing key, assume its correct
                } else {
                    $existingLicenseKey = $existingConfig.OctopusLicenseKey
                }
                $existingPackagesDirectory = $existingConfig.OctopusFoldersPackagesDirectory
                $existingTaskLogsDirectory = $existingConfig.OctopusFoldersLogDirectory
                $existingArtifactsDirectory = $existingConfig.OctopusFoldersArtifactsDirectory
                $existingLogTaskMetrics = $existingConfig.OctopusTasksRecordTaskMetrics
                $existingLogRequestMetrics = $existingConfig.OctopusWebPortalRequestMetricLoggingEnabled

                #note: this can get out of sync with reality. Ideally we'd read from `show-configuration`,
                #      but the catch is there can be multple admins. We'd probably need to add support for
                #      an `--assert` or `--validate` parameter to the `admin` command and check its valid
                $user = Get-InstallStateValue 'OctopusAdminUsername'
                $pass = Get-InstallStateValue 'OctopusAdminPassword'
                if (($null -ne $user) -and ($null -ne $pass)) {
                    $existingOctopusAdminCredential = New-Object System.Management.Automation.PSCredential ($user, ($pass | ConvertTo-SecureString))
                }

                #note: this should read from the service. How do we validate the password though? We moght
                #      need to add support for an `--assert` or `--validate` parameter to the `service`
                #      command and check its valid
                $user = Get-InstallStateValue 'OctopusServiceUsername'
                $pass = Get-InstallStateValue 'OctopusServicePassword'
                if (($null -ne $user) -and ($null -ne $pass)) {
                    $existingOctopusServiceCredential = New-Object System.Management.Automation.PSCredential ($user, ($pass | ConvertTo-SecureString))
                }

                #note: this should read from `show-configuration`. That wont validate the password is set
                #      correctly though. We'd probably need to add support for an `--assert` or
                #      `--validate` parameter to the `runonserver` command and check its valid
                $user = Get-InstallStateValue 'OctopusRunAsUsername'
                $pass = Get-InstallStateValue 'OctopusRunAsPassword'
                if (($null -ne $user) -and ($null -ne $pass)) {
                    $existingOctopusBuiltInWorkerCredential = New-Object System.Management.Automation.PSCredential ($user, ($pass | ConvertTo-SecureString))
                }
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
            HSTSEnabled                               = $existingHSTSEnabled;
            HSTSMaxAge                                = $existingHSTSMaxAge;
            AllowUpgradeCheck                         = $existingOctopusUpgradesAllowChecking;
            AllowCollectionOfUsageStatistics          = $existingOctopusUpgradesIncludeStatistics;
            ListenPort                                = $existingListenPort;
            OctopusAdminCredential                    = $existingOctopusAdminCredential;
            LegacyWebAuthenticationMode               = $existingLegacyWebAuthenticationMode;
            AutoLoginEnabled                          = $existingAutoLoginEnabled;
            OctopusServiceCredential                  = $existingOctopusServiceCredential;
            HomeDirectory                             = $existingHomeDirectory;
            ServerLogsDirectory                       = $existingServerLogsDirectory;
            ServerMetricsDirectory                    = $existingServerMetricsDirectory;
            LicenseKey                                = $existingLicenseKey;
            GrantDatabasePermissions                  = $GrantDatabasePermissions;
            OctopusBuiltInWorkerCredential            = $existingOctopusBuiltInWorkerCredential;
            PackagesDirectory                         = $existingPackagesDirectory;
            ArtifactsDirectory                        = $existingArtifactsDirectory;
            TaskLogsDirectory                         = $existingTaskLogsDirectory;
            LogTaskMetrics                            = $existingLogTaskMetrics;
            LogRequestMetrics                         = $existingLogRequestMetrics;
        }

        return $currentResource
    } catch {
        Resolve-Error $_
        throw
    }
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

        # show-configuration only added support for the license from 4.1.3
        # unfortunately, $null implies that its the free license, so it would trigger a change every time DSC runs
        if ([bool]($config.Octopus.Server.psobject.properties.name -match 'License')) {
            $license = $config.Octopus.Server.License
        } else {
            $license = '<unknown>'
        }

        $result = [pscustomobject] @{
            OctopusStorageExternalDatabaseConnectionString = $config.Octopus.Storage.ExternalDatabaseConnectionString
            OctopusWebPortalListenPrefixes                 = $config.Octopus.WebPortal.ListenPrefixes
            OctopusWebPortalForceSsl                       = [System.Convert]::ToBoolean($config.Octopus.WebPortal.ForceSSL)
            OctopusWebPortalHstsEnabled                    = [System.Convert]::ToBoolean($config.Octopus.WebPortal.HttpStrictTransportSecurityEnabled)
            OctopusWebPortalHstsMaxAge                     = $config.Octopus.WebPortal.HttpStrictTransportSecurityMaxAge
            OctopusUpgradesAllowChecking                   = [System.Convert]::ToBoolean($config.Octopus.Upgrades.AllowChecking)
            OctopusUpgradesIncludeStatistics               = [System.Convert]::ToBoolean($config.Octopus.Upgrades.IncludeStatistics)
            OctopusCommunicationsServicesPort              = $config.Octopus.Communications.ServicesPort
            OctopusWebPortalAuthenticationMode             = "Ignore"
            OctopusWebPortalAutoLoginEnabled               = [System.Convert]::ToBoolean($config.Octopus.WebPortal.AutoLoginEnabled)
            OctopusHomeDirectory                           = $config.Octopus.Home
            OctopusFoldersServerLogsDirectory              = $config.Octopus.Folders.ServerLogsDirectory
            OctopusFoldersServerMetricsDirectory           = $config.Octopus.Folders.ServerMetricsDirectory
            OctopusLicenseKey                              = $license
            OctopusFoldersLogDirectory                     = $config.Octopus.Folders.LogDirectory
            OctopusFoldersArtifactsDirectory               = $config.Octopus.Folders.ArtifactsDirectory
            OctopusFoldersPackagesDirectory                = $config.Octopus.Folders.PackagesDirectory
            OctopusTasksRecordTaskMetrics                  = [System.Convert]::ToBoolean($config.Octopus.Tasks.RecordTaskMetrics)
            OctopusWebPortalRequestMetricLoggingEnabled    = [System.Convert]::ToBoolean($config.Octopus.WebPortal.RequestMetricLoggingEnabled)
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
            OctopusLicenseKey                              = '<unknown>' # we have no easy way to get this
        }

        if ($result.OctopusWebPortalAuthenticationMode -eq '0') { $result.OctopusWebPortalAuthenticationMode = 'UsernamePassword' }
        elseif ($result.OctopusWebPortalAuthenticationMode -eq '1') { $result.OctopusWebPortalAuthenticationMode = 'Domain' }
    }
    return $result
}

function Test-OctopusVersionSupportsAutoLoginEnabled {
    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 5, 0)
}

function Test-OctopusVersionSupportsHsts {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    param()

    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 13, 0)
}

function Test-OctopusVersionSupportsRunAsCredential {
    return Test-OctopusVersionNewerThan (New-Object System.Version 2018, 1, 0)
}

function Test-OctopusVersionSupportsShowConfiguration {
    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 5, 0)
}

function Test-OctopusVersionSupportsHomeDirectoryDuringCreateInstance {
    return Test-OctopusVersionNewerThan (New-Object System.Version 3, 16, 4)
}

function Test-OctopusVersionRequiresDatabaseBeforeConfigure {
    return Test-OctopusVersionNewerThan (New-Object System.Version 4, 0, 0)
}

function Test-OctopusVersionSupportsTaskMetricsLogging {
    return Test-OctopusVersionNewerThan (New-Object System.Version 2018, 2, 7)
}

function Test-OctopusVersionNewerThan($targetVersion) {
    if (-not (Test-Path -LiteralPath $octopusServerExePath)) {
        throw "Octopus.Server.exe path '$octopusServerExePath' does not exist."
    }

    $exeFile = Get-Item -LiteralPath $octopusServerExePath -ErrorAction Stop
    if ($exeFile -isnot [System.IO.FileInfo]) {
        throw "Octopus.Server.exe path '$octopusServerExePath' does not refer to a file."
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
        [string]$Name,
        [ValidateSet("Started", "Stopped", "Installed")]
        [string]$State = "Started",
        [string]$DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
        [string]$WebListenPrefix,
        [string]$SqlDbConnectionString,
        [PSCredential]$OctopusAdminCredential,
        [bool]$AllowUpgradeCheck = $true,
        [bool]$AllowCollectionOfUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$LegacyWebAuthenticationMode = 'Ignore',
        [bool]$ForceSSL = $false,
        [bool]$HSTSEnabled = $false,
        [Int64]$HSTSMaxAge = 3600, # 1 hour
        [int]$ListenPort = 10943,
        [Nullable[bool]]$AutoLoginEnabled = $null,
        [PSCredential]$OctopusServiceCredential,
        [string]$HomeDirectory = "$($env:SystemDrive)\Octopus",
        [string]$ServerLogsDirectory = "$HomeDirectory\Logs",
        [string]$ServerMetricsDirectory = "$HomeDirectory\Logs",
        [PSCredential]$OctopusMasterKey = [PSCredential]::Empty,
        [string]$LicenseKey = $null,
        [bool]$GrantDatabasePermissions = $true,
        [PSCredential]$OctopusBuiltInWorkerCredential = [PSCredential]::Empty,
        [string]$PackagesDirectory = "$HomeDirectory\Packages",
        [string]$ArtifactsDirectory = "$HomeDirectory\Artifacts",
        [string]$TaskLogsDirectory = "$HomeDirectory\TaskLogs",
        [bool]$LogTaskMetrics = $false,
        [bool]$LogRequestMetrics = $false
    )

    try {
        Test-ParameterSet -Ensure $Ensure `
                          -Name $Name `
                          -State $State `
                          -DownloadUrl $DownloadUrl `
                          -WebListenPrefix $WebListenPrefix `
                          -SqlDbConnectionString $SqlDbConnectionString `
                          -OctopusAdminCredential $OctopusAdminCredential

        # update the global
        $script:instancecontext = $Name

        $currentResource = (Get-TargetResource -Ensure $Ensure `
                -Name $Name `
                -State $State `
                -DownloadUrl $DownloadUrl `
                -WebListenPrefix $WebListenPrefix `
                -SqlDbConnectionString $SqlDbConnectionString `
                -OctopusAdminCredential $OctopusAdminCredential `
                -AllowUpgradeCheck $AllowUpgradeCheck `
                -AllowCollectionOfUsageStatistics $AllowCollectionOfUsageStatistics `
                -LegacyWebAuthenticationMode $LegacyWebAuthenticationMode `
                -ForceSSL $ForceSSL `
                -HSTSEnabled $HSTSEnabled `
                -HSTSMaxAge $HSTSMaxAge `
                -ListenPort $ListenPort `
                -AutoLoginEnabled $AutoLoginEnabled `
                -OctopusServiceCredential $OctopusServiceCredential `
                -HomeDirectory $HomeDirectory `
                -ServerLogsDirectory $ServerLogsDirectory `
                -ServerMetricsDirectory $ServerMetricsDirectory `
                -OctopusMasterKey $OctopusMasterKey `
                -LicenseKey $LicenseKey `
                -GrantDatabasePermissions $GrantDatabasePermissions `
                -OctopusBuiltInWorkerCredential $OctopusBuiltInWorkerCredential `
                -PackagesDirectory $PackagesDirectory `
                -ArtifactsDirectory $ArtifactsDirectory `
                -TaskLogsDirectory $TaskLogsDirectory `
                -LogTaskMetrics $LogTaskMetrics `
                -LogRequestMetrics $LogRequestMetrics)

        $params = Get-ODSCParameter $MyInvocation.MyCommand.Parameters
        Test-RequestedConfiguration $currentResource $params

        $isCurrentlyNotInstalled = $currentResource["Ensure"] -eq "Absent"
        $isCurrentlyInstalledAndServiceExists = $currentResource["Ensure"] -eq "Present"

        $isCurrentlyInstalledButServiceDoesntExist = $currentResource["State"] -eq "Installed"
        $isCurrentlyStarted = $currentResource["State"] -eq "Started"
        $isCurrentlyStopped = $currentResource["State"] -eq "Stopped"

        $stopRequested = $State -eq "Stopped"
        $startRequested = $State -eq "Started"
        $removeRequested = $Ensure -eq "Absent"
        $installRequested = $State -eq "Installed"
        $installAndConfigureRequested = $Ensure -eq "Present" -and $State -ne "Installed"

        if ($stopRequested -and $isCurrentlyStarted) {
            Stop-OctopusDeployService $Name
        }

        if ($removeRequested -and ($isCurrentlyInstalledAndServiceExists -or $isCurrentlyInstalledButServiceDoesntExist)) {
            Uninstall-OctopusDeploy -name $Name -currentState $currentResource["State"]
        }
        elseif ($installRequested -and $isCurrentlyNotInstalled) {
            #no stop/start required
            Install-MSI $DownloadUrl
        }
        elseif ($installAndConfigureRequested -and ($isCurrentlyNotInstalled -or $isCurrentlyInstalledButServiceDoesntExist)) {
            #they've asked for it to be installed + configured and its not there yet
            if ($isCurrentlyNotInstalled -or ($currentResource["DownloadUrl"] -ne $DownloadUrl)) {
                #no stop/start required
                Install-MSI $DownloadUrl
            }
            Install-OctopusDeploy -name $Name `
                -webListenPrefix $WebListenPrefix `
                -sqlDbConnectionString $SqlDbConnectionString `
                -OctopusAdminCredential $OctopusAdminCredential `
                -allowUpgradeCheck $AllowUpgradeCheck `
                -allowCollectionOfUsageStatistics $AllowCollectionOfUsageStatistics `
                -legacyWebAuthenticationMode $LegacyWebAuthenticationMode `
                -forceSSL $ForceSSL `
                -hstsEnabled $HSTSEnabled `
                -hstsMaxAge $HSTSMaxAge `
                -listenPort $ListenPort `
                -autoLoginEnabled $AutoLoginEnabled `
                -homeDirectory $HomeDirectory `
                -serverLogsDirectory $ServerLogsDirectory `
                -serverMetricsDirectory $ServerMetricsDirectory `
                -octopusServiceCredential $OctopusServiceCredential `
                -OctopusMasterKey $OctopusMasterKey `
                -licenseKey $LicenseKey `
                -grantDatabasePermissions $GrantDatabasePermissions `
                -octopusBuiltInWorkerCredential $OctopusBuiltInWorkerCredential `
                -packagesDirectory $PackagesDirectory `
                -artifactsDirectory $ArtifactsDirectory `
                -taskLogsDirectory $TaskLogsDirectory `
                -logTaskMetrics $LogTaskMetrics `
                -logRequestMetrics $LogRequestMetrics 
        } else {
            #have they asked for a new msi?
            if ($installAndConfigureRequested -and $currentResource["DownloadUrl"] -ne $DownloadUrl) {
                Update-OctopusDeploy -name $Name `
                    -downloadUrl $DownloadUrl `
                    -state $State `
                    -webListenPrefix $webListenPrefix `
                    -currentState $currentResource["State"]
            }

            #are there any changes that need to be applied?
            if (Test-ReconfigurationRequired $currentResource $params) {
                Set-OctopusDeployConfiguration `
                    -currentState $currentResource `
                    -name $Name `
                    -webListenPrefix $WebListenPrefix `
                    -allowUpgradeCheck $AllowUpgradeCheck `
                    -allowCollectionOfUsageStatistics $AllowCollectionOfUsageStatistics `
                    -legacyWebAuthenticationMode $LegacyWebAuthenticationMode `
                    -forceSSL $ForceSSL `
                    -hstsEnabled $HSTSEnabled `
                    -hstsMaxAge $HSTSMaxAge `
                    -listenPort $ListenPort `
                    -autoLoginEnabled $AutoLoginEnabled `
                    -homeDirectory $HomeDirectory `
                    -serverLogsDirectory $ServerLogsDirectory `
                    -serverMetricsDirectory $ServerMetricsDirectory `
                    -octopusServiceCredential $OctopusServiceCredential `
                    -OctopusMasterKey $OctopusMasterKey `
                    -licenseKey $LicenseKey `
                    -octopusBuiltInWorkerCredential $OctopusBuiltInWorkerCredential `
                    -packagesDirectory $PackagesDirectory `
                    -artifactsDirectory $ArtifactsDirectory `
                    -taskLogsDirectory $TaskLogsDirectory `
                    -logTaskMetrics $LogTaskMetrics `
                    -logRequestMetrics $LogRequestMetrics
            }
        }

        if ($startRequested -and ($isCurrentlyStopped -or $isCurrentlyInstalledButServiceDoesntExist)) {
            Start-OctopusDeployService -name $Name -webListenPrefix $webListenPrefix
        }
    } catch {
        Resolve-Error $_
        throw
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
        [Hashtable]$currentState,
        [Parameter(Mandatory = $True)]
        [string]$name,
        [Parameter(Mandatory = $True)]
        [string]$webListenPrefix,
        [Parameter(Mandatory)]
        [bool]$allowUpgradeCheck = $true,
        [bool]$allowCollectionOfUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$legacyWebAuthenticationMode = 'Ignore',
        [bool]$forceSSL = $false,
        [bool]$hstsEnabled = $false,
        [Int64]$hstsMaxAge = 3600, # 1 hour
        [int]$listenPort = 10943,
        [Nullable[bool]]$autoLoginEnabled = $null,
        [string]$homeDirectory = $null,
        [string]$serverLogsDirectory = $null,
        [string]$serverMetricsDirectory = $null,
        [PSCredential]$OctopusServiceCredential,
        [PSCredential]$OctopusMasterKey,
        [string]$licenseKey = $null,
        [PSCredential]$OctopusBuiltInWorkerCredential = [PSCredential]::Empty,
        [string]$packagesDirectory = $null,
        [string]$artifactsDirectory = $null,
        [string]$taskLogsDirectory = $null,
        [bool]$logTaskMetrics = $false,
        [bool]$logRequestMetrics = $false
    )

    Write-Log "Configuring Octopus Deploy instance ..."
    $args = @(
        'configure',
        '--console',
        '--instance', $name,
        '--upgradeCheck', $allowUpgradeCheck,
        '--upgradeCheckWithStatistics', $allowCollectionOfUsageStatistics,
        '--webForceSSL', $forceSSL,
        '--webListenPrefixes', $webListenPrefix,
        '--commsListenPort', $listenPort
    )
    if (($homeDirectory -ne "") -and ($null -ne $homeDirectory)) {
        $args += @('--home', $homeDirectory)
    }

    if ($null -ne $autoLoginEnabled) {
        if (Test-OctopusVersionSupportsAutoLoginEnabled) {
            $args += @('--autoLoginEnabled', $autoLoginEnabled)
        }
        else {
            throw "AutoLoginEnabled is only supported from Octopus 3.5.0. Please pass `$null for versions older than this."
        }
    }

    if (Test-OctopusVersionSupportsHsts) {
        $args += @(
            '--hstsEnabled', $hstsEnabled,
            '--hstsMaxAge', $hstsMaxAge
        )
    }
    elseif ($hstsEnabled) {
        throw "HSTS is only supported for Octopus versions newer than 3.13.0"
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

    if (
            (($null -ne $packagesDirectory) -and ($currentState['PackagesDirectory'] -ne $packagesDirectory)) -or
            (($null -ne $artifactsDirectory) -and ($currentState['ArtifactsDirectory'] -ne $artifactsDirectory)) -or
            (($null -ne $taskLogsDirectory) -and ($currentState['TaskLogsDirectory'] -ne $taskLogsDirectory))
        ) {
        $args = $(
            'path',
            '--console',
            '--instance', $name
        )
        if (($null -ne $packagesDirectory) -and ($currentState['PackagesDirectory'] -ne $packagesDirectory)) {
            $args += @('--nugetRepository', $packagesDirectory)
        }
        if (($null -ne $artifactsDirectory) -and ($currentState['ArtifactsDirectory'] -ne $artifactsDirectory)) {
            $args += @('--artifacts', $artifactsDirectory)
        }
        if (($null -ne $taskLogsDirectory) -and ($currentState['TaskLogsDirectory'] -ne $taskLogsDirectory)) {
            $args += @('--taskLogs', $taskLogsDirectory)
        }
        Invoke-OctopusServerCommand $args
    }

    if ((-not (Test-OctopusVersionSupportsTaskMetricsLogging)) -and $logTaskMetrics) {
        throw "LogTaskMetrics = 'true' is only supported from Octopus 2018.2.7"
    }

    if (
            (($null -ne $logTaskMetrics) -and ($currentState['LogTaskMetrics'] -ne $logTaskMetrics)) -or
            (($null -ne $logRequestMetrics) -and ($currentState['LogRequestMetrics'] -ne $logRequestMetrics))
        ) {
        $args = $(
            'metrics',
            '--console',
            '--instance', $name
        )
        if (($null -ne $logTaskMetrics) -and ($currentState['LogTaskMetrics'] -ne $logTaskMetrics)) {
            $args += @('--tasks', $logTaskMetrics)
        }
        if (($null -ne $logRequestMetrics) -and ($currentState['LogRequestMetrics'] -ne $logRequestMetrics)) {
            $args += @('--webapi', $logRequestMetrics)
        }
        Invoke-OctopusServerCommand $args
    }

    if (-not (Test-PSCredential $currentState['OctopusServiceCredential'] $OctopusServiceCredential)) {
        $args = @(
            'service',
            '--console',
            '--instance', $name,
            '--stop',
            '--start',
            '--reconfigure'
        )

        if (($null -ne $octopusServiceCredential) -and ($octopusServiceCredential -ne [PSCredential]::Empty)) {
            Write-Log "Reconfiguring Octopus Deploy service to use run as $($octopusServiceCredential.UserName) ..."
            $args += @(
                '--username', $octopusServiceCredential.UserName,
                '--password', $octopusServiceCredential.GetNetworkCredential().Password
            )

            Update-InstallState "OctopusServiceUsername" $octopusServiceCredential.UserName
            Update-InstallState "OctopusServicePassword" ($octopusServiceCredential.Password | ConvertFrom-SecureString)
        }
        else {
            Write-Log "Reconfiguring Octopus Deploy service to run as Local System ..."
            Update-InstallState "OctopusServiceUsername" $null
            Update-InstallState "OctopusServicePassword" $null
        }
        Invoke-OctopusServerCommand $args
    }

    if (-not (Test-PSCredential $currentState['OctopusAdminCredential'] $OctopusAdminCredential)) {
        if (($null -ne $octopusAdminCredential) -and ($octopusAdminCredential -ne [PSCredential]::Empty)) {
            Write-Log "Updating Octopus Deploy admin user to $($octopusAdminCredential.UserName) ..."
            $args = @(
                'admin',
                '--console'
                '--instance', $name,
                '--username', $octopusAdminCredential.UserName,
                '--password', $octopusAdminCredential.GetNetworkCredential().Password
            )

            Update-InstallState "OctopusAdminUsername" $octopusAdminCredential.UserName
            Update-InstallState "OctopusAdminPassword" ($octopusAdminCredential.Password | ConvertFrom-SecureString)
        }
        else {
            throw "'OctopusBuiltInWorkerCredential' must be supplied"
        }
        Invoke-OctopusServerCommand $args
    }

    if ($currentState['LicenseKey'] -ne $licenseKey) {
        $args = @(
            'license',
            '--console',
            '--instance', $name
        )
        if (($null -eq $licenseKey) -or ($licenseKey -eq "")) {
            Write-Log "Configuring Octopus Deploy instance to use free license ..."
            $args += @('--free')
        } else {
            Write-Log "Configuring Octopus Deploy instance to use supplied license ..."
            $args += @('--licenseBase64', $licenseKey)
        }
        Invoke-OctopusServerCommand $args
    }

    if (-not (Test-PSCredential $currentState['OctopusBuiltInWorkerCredential'] $octopusBuiltInWorkerCredential)) {
        if (Test-OctopusVersionSupportsRunAsCredential) {
            if (($null -ne $octopusBuiltInWorkerCredential) -and ($octopusBuiltInWorkerCredential -ne [PSCredential]::Empty)) {
                Write-Log "Configuring Octopus Deploy to execute run-on-server scripts as $($octopusBuiltInWorkerCredential.UserName) ..."

                $args = @(
                    'builtin-worker',
                    '--instance', $name,
                    '--username', $octopusBuiltInWorkerCredential.UserName
                    '--password', $octopusBuiltInWorkerCredential.GetNetworkCredential().Password
                )
                Update-InstallState "OctopusRunAsUsername" $octopusBuiltInWorkerCredential.UserName
                Update-InstallState "OctopusRunAsPassword" ($octopusBuiltInWorkerCredential.Password | ConvertFrom-SecureString)
            } else {
                Write-Log "Configuring Octopus Deploy to execute run-on-server scripts under the same account as the octopus.server.exe process..."
                $args = @(
                    'builtin-worker',
                    '--instance', $name,
                    '--reset'
                )
                Update-InstallState "OctopusRunAsUsername" $null
                Update-InstallState "OctopusRunAsPassword" $null
            }
            Invoke-OctopusServerCommand $args
        } else {
            throw "'OctopusBuiltInWorkerCredential' is only supported from Octopus 2018.1.0 and newer."
        }
    }
}

function Test-ReconfigurationRequired($currentState, $desiredState) {
    $reconfigurableProperties = @('ListenPort', 'WebListenPrefix', 'ForceSSL', 'HSTSEnabled', 'HSTSMaxAge', 'AllowCollectionOfUsageStatistics', 'AllowUpgradeCheck', 'LegacyWebAuthenticationMode', 'HomeDirectory', 'ServerLogsDirectory', 'ServerMetricsDirectory', 'LicenseKey', 'OctopusServiceCredential', 'OctopusAdminCredential', 'SqlDbConnectionString', 'AutoLoginEnabled', 'OctopusBuiltInWorkerCredential', 'TaskLogsDirectory', 'PackagesDirectory', 'ArtifactsDirectory', 'LogTaskMetrics', 'LogRequestMetrics')
    foreach ($property in $reconfigurableProperties) {
        write-verbose "Checking property '$property'"
        if ($currentState.Item($property) -is [PSCredential]) {
            if (-not (Test-PSCredential $currentState.Item($property) $desiredState.Item($property))) {
                return $true
            }
        }
        elseif ($currentState.Item($property) -ne ($desiredState.Item($property))) {
            return $true
        }
    }
    return $false
}

function Uninstall-OctopusDeploy($name, $currentState) {
    if ($currentState -eq "Started" -or $currentState -eq "Stopped") {
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
    }

    $otherServices = Get-ExistingOctopusServices
    if ($otherServices.length -eq 0) {
        # Uninstall msi
        Write-Verbose "Uninstalling Octopus..."
        $logDirectory = Get-LogDirectory
        $msiPath = "$($env:SystemDrive)\Octopus\Octopus-x64.msi"
        $msiLog = "$logDirectory\Octopus-x64.msi.uninstall.log"
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

function Get-LogDirectory {
    $logDirectory = "$($env:SystemDrive)\Octopus\logs"
    if (-not (Test-Path $logDirectory)) { New-Item -type Directory $logDirectory | out-null }
    return $logDirectory
}

function Get-ExistingOctopusServices {
    return @(Get-CimInstance win32_service | Where-Object {$_.PathName -like "`"$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe*"})
}

function Update-OctopusDeploy($name, $downloadUrl, $state, $webListenPrefix, $currentState) {
    Write-Verbose "Upgrading Octopus Deploy..."
    Install-MSI $downloadUrl -StopService:($currentState -eq "Started")
    if ($state -eq "Started") {
        Start-OctopusDeployService -name $name -webListenPrefix $webListenPrefix
    }
    Write-Verbose "Octopus Deploy upgraded!"
}

function Start-OctopusDeployService($name, $webListenPrefix) {
    Write-Log "Checking Octopus Deploy service state:"
    get-service $name  -ErrorAction SilentlyContinue | write-verbose

    Write-Log "Starting Octopus Deploy instance ..."
    $args = @(
        'service',
        '--start',
        '--console',
        '--instance', $name
    )
    Invoke-OctopusServerCommand $args

    # split on semi colons for backwards compat
    $url = ($webListenPrefix -split ';')[0]
    # but also split on commas, as Octopus supports both
    $url = ($url -split ',')[0]

    $timeout = new-timespan -Minutes 5
    $sw = [diagnostics.stopwatch]::StartNew()
    while (($sw.elapsed -lt $timeout) -and (-not (Test-OctopusDeployServerResponding $url))) {
        Write-Verbose "$(date) Waiting until server completes startup"
        Start-Sleep -Seconds 5
    }

    if (-not (Test-OctopusDeployServerResponding $url)) {
        throw "Server did not come online at $url after $($timeout.TotalMinutes) minutes"
    }
}

function Test-OctopusDeployServerResponding($url) {
    try {
        Write-Verbose "Checking if $url/api is responding..."
        Invoke-WebRequest "$url/api" -UseBasicParsing | Out-Null
        Write-Verbose "Got a successful response from $url/api"
        return $true
    }
    catch {
        write-verbose "Server returned error $($_)"
        return $false
    }
}

function Stop-OctopusDeployService($name) {
    Write-Log "Checking Octopus Deploy service state:"
    get-service $name  -ErrorAction SilentlyContinue | write-verbose

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

function Invoke-MsiExec ($logDirectory) {
    Write-Verbose "Installing MSI..."
    if (-not (Test-Path "$($env:SystemDrive)\Octopus\logs")) { New-Item -type Directory "$($env:SystemDrive)\Octopus\logs" }
    $msiLog = "$logDirectory\Octopus-x64.msi.log"
    $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /quiet /l*v $msiLog" -Wait -Passthru).ExitCode
    Write-Verbose "MSI installer returned exit code $msiExitCode"
    if ($msiExitCode -ne 0) {
        throw "Installation of the MSI failed; MSIEXEC exited with code: $msiExitCode. View the log at $msiLog"
    }
}

function Install-MSI {
    param (
        [string]$downloadUrl,
        [switch]$stopService = $false
    )
    Write-Verbose "Beginning installation"
    $logDirectory = Get-LogDirectory

    $msiPath = "$($env:SystemDrive)\Octopus\Octopus-x64.msi"
    Request-File $downloadUrl $msiPath

    if ($stopService) {
        Stop-OctopusDeployService -name $name
    }
    Invoke-MsiExec $logDirectory

    Update-InstallState "DownloadUrl" $downloadUrl -global
}

function Update-InstallState {
    param (
        [string]$key,
        [string]$value,
        [switch]$global = $false
    )

    if ((Test-Path "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate") -or $global) # do we already have a legacy installstate file, or are we writing global settings?
    {
        $installStateFile = "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate"
    }
    else
    {
        $installStateFile = "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.$script:instancecontext.installstate"
    }

    $currentInstallState = @{}
    if (Test-Path $installStateFile) {
        $fileContent = (Get-Content -Raw -Path $installStateFile | ConvertFrom-Json)
        $fileContent.psobject.properties | ForEach-Object { $currentInstallState[$_.Name] = $_.Value }
    }

    $currentInstallState.Set_Item($key, $value)

    $currentInstallState | ConvertTo-Json | set-content $installStateFile
}

function Get-InstallStateValue {
    [CmdletBinding()]
        param (
        [string]$key,
        [switch]$global = $false
    )

    if ((Test-Path "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate") -or $global) # do we already have a legacy installstate file, or are we writing global settings?
    {
        $installStateFile = "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.installstate"
    }
    else
    {
        $installStateFile = "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.$script:instancecontext.installstate"
    }

    if(-not (Test-Path $installStateFile))
    {
        return $null
    }
    else
    {
        $installState = (Get-Content -Raw -Path $installStateFile | ConvertFrom-Json)

        $returnValue = $installstate | Select-Object -expand $Key -ErrorAction Ignore
        if("" -eq $returnValue -or $null -eq $returnValue)
        {
            return $null
        }
        else
        {
            return $returnvalue
        }
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
        [string]$webListenPrefix,
        [Parameter(Mandatory = $True)]
        [string]$sqlDbConnectionString,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$octopusAdminCredential,
        [bool]$allowUpgradeCheck = $true,
        [bool]$allowCollectionOfUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$legacyWebAuthenticationMode = 'Ignore',
        [bool]$forceSSL = $false,
        [bool]$hstsEnabled = $false,
        [Int64]$hstsMaxAge = 3600, # 1 hour
        [int]$listenPort = 10943,
        [Nullable[bool]]$autoLoginEnabled = $null,
        [string]$homeDirectory = $null,
        [string]$serverLogsDirectory = $null,
        [string]$serverMetricsDirectory = $null,
        [PSCredential]$octopusServiceCredential,
        [PSCredential]$OctopusMasterKey,
        [string]$licenseKey = $null,
        [bool]$grantDatabasePermissions = $true,
        [PSCredential]$OctopusBuiltInWorkerCredential, 
        [string]$taskLogsDirectory = $null,
        [string]$packagesDirectory = $null,
        [string]$artifactsDirectory = $null,
        [bool]$logTaskMetrics = $false,
        [bool]$logRequestMetrics = $false
    )

    Write-Verbose "Installing Octopus Deploy..."

    Write-Log "Checking to make sure .net 4.5.1+ is installed"
    $dotnetVersion = Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
    if (($dotnetVersion -eq "") -or ([int]$dotnetVersion -lt 378675)) {
        throw "Octopus Server requires .NET 4.5.1. Please install it before attempting to install Octopus Server."
    }

    $extractedUserName = $octopusAdminCredential.GetNetworkCredential().UserName
    $extractedPassword = $octopusAdminCredential.GetNetworkCredential().Password

    # check if we're joining a cluster, or joining to an existing Database
    $isMasterKeyProvided = ($OctopusMasterKey -ne [PSCredential]::Empty)

    Write-Log "Creating Octopus Deploy instance ..."
    $args = @(
        'create-instance',
        '--console',
        '--instance', $name,
        '--config', "$($env:SystemDrive)\Octopus\OctopusServer-$name.config"
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

    $args = @(
        'configure',
        '--console',
        '--instance', $name,
        '--upgradeCheck', $allowUpgradeCheck,
        '--upgradeCheckWithStatistics', $allowCollectionOfUsageStatistics,
        '--webForceSSL', $forceSSL,
        '--webListenPrefixes', $webListenPrefix,
        '--commsListenPort', $listenPort
    )

    if (Test-OctopusVersionRequiresDatabaseBeforeConfigure) {
        if ($isMasterKeyProvided) {
            Write-Log "Running Octopus Deploy database command for existing database with provided masterkey"
            $dbargs = @(
                'database',
                '--instance', $name,
                '--connectionstring', $sqlDbConnectionString,
                "--masterKey", $OctopusMasterKey.GetNetworkCredential().Password
            )
        }
        else {
            Write-Log "Creating Octopus Deploy database for v4"
            $action = '--create'

            $dbargs = @(
                'database',
                '--instance', $name,
                '--connectionstring', $sqlDbConnectionString,
                $action
            )
        }

        if ($GrantDatabasePermissions) {
            if (($null -ne $OctopusServiceCredential) -and ($OctopusServiceCredential -ne [PSCredential]::Empty)) {
                $databaseusername = $OctopusServiceCredential.UserName
            }
            else {
                $databaseusername = "NT AUTHORITY\SYSTEM"
            }
            Write-Log "Granting database permissions to account $databaseusername"
            $dbargs += @('--grant', $databaseusername)
        }

        Invoke-OctopusServerCommand $dbargs
    }
    else {
        $args += @("--StorageConnectionString", $sqlDbConnectionString)

        if ($isMasterKeyProvided) {
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

    if ($null -ne $autoLoginEnabled) {
        if (Test-OctopusVersionSupportsAutoLoginEnabled) {
            $args += @('--autoLoginEnabled', $autoLoginEnabled)
        }
        else {
            throw "AutoLoginEnabled is only supported from Octopus 3.5.0. Please pass `$null for versions older than this."
        }
    }

    if (Test-OctopusVersionSupportsHsts) {
        $args += @(
            '--hstsEnabled', $hstsEnabled,
            '--hstsMaxAge', $hstsMaxAge
        )
    }
    elseif ($hstsEnabled) {
        throw "HSTS is only supported for Octopus versions newer than 3.13.0"
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

        if ($isMasterKeyProvided) {
            $args += @("--masterKey", $OctopusMasterKey.GetNetworkCredential().Password)
        }

        if ($GrantDatabasePermissions) {
            if (($null -ne $OctopusServiceCredential) -and ($OctopusServiceCredential -ne [PSCredential]::Empty)) {
                $databaseusername = $OctopusServiceCredential.UserName
            }
            else {
                $databaseusername = "NT AUTHORITY\SYSTEM"
            }
            Write-Log "Granting database permissions to account $databaseusername"
            $args += @('--grant', $databaseusername)
        }

        Invoke-OctopusServerCommand $args
    }

    Stop-OctopusDeployService -name $name

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

    $args = @(
        'license',
        '--console',
        '--instance', $name
    )
    if (($null -eq $licenseKey) -or ($licenseKey -eq "")) {
        Write-Log "Configuring Octopus Deploy instance to use free license ..."
        $args += @('--free')
    } else {
        Write-Log "Configuring Octopus Deploy instance to use supplied license ..."
        $args += @('--licenseBase64', $licenseKey)
    }
    Invoke-OctopusServerCommand $args

    if (($null -ne $packagesDirectory) -or ($null -ne $artifactsDirectory) -or ($null -ne $taskLogsDirectory)) {
        $args = $(
            'path',
            '--console',
            '--instance', $name
        )
        if ($null -ne $packagesDirectory) {
            $args += @('--nugetRepository', $packagesDirectory)
        }
        if ($null -ne $artifactsDirectory) {
            $args += @('--artifacts', $artifactsDirectory)
        }
        if ($null -ne $taskLogsDirectory) {
            $args += @('--taskLogs', $taskLogsDirectory)
        }
        Invoke-OctopusServerCommand $args
    }

    if ((-not (Test-OctopusVersionSupportsTaskMetricsLogging)) -and $logTaskMetrics) {
        throw "LogTaskMetrics = 'true' is only supported from Octopus 2018.2.7"
    }

    if ($logTaskMetrics -or $logRequestMetrics) {
        $args = $(
            'metrics',
            '--console',
            '--instance', $name
        )

        if ($logTaskMetrics) {
            $args += @('--tasks', $logTaskMetrics)
        }
        if ($logRequestMetrics) {
            $args += @('--webapi', $logRequestMetrics)
        }
        Invoke-OctopusServerCommand $args
    }

    if (($serverLogsDirectory -ne "$homeDirectory\Logs") -or ($serverMetricsDirectory -ne "$homeDirectory\Logs")) {
        $nlogPath = "$octopusServerExePath.nlog"
        $nlogConfig = Get-NLogConfig -Path $nlogPath

        if ($serverLogsDirectory -ne "$homeDirectory\Logs") {
            Write-Log "Setting the Octopus Server Logs directory to $serverLogsDirectory ..."
            Set-NLogConfig -NLogConfig $nlogConfig -Target "octopus-log-file" -Destination $serverLogsDirectory
        }
        if ($serverMetricsDirectory -ne "$homeDirectory\Logs") {
            Write-Log "Setting the Octopus Server Metrics directory to $serverMetricsDirectory ..."
            Set-NLogConfig -NLogConfig $nlogConfig -Target "octopus-metrics-file" -Destination $serverMetricsDirectory
        }

        Save-NlogConfig -NLogConfig $xml -Path $nlogPath
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
        Write-Log "Configuring service to run as $($octopusServiceCredential.UserName)"
        $args += @(
            "--username", $octopusServiceCredential.UserName,
            "--password", $octopusServiceCredential.GetNetworkCredential().Password
        )
        Update-InstallState "OctopusServiceUsername" $octopusServiceCredential.UserName
        Update-InstallState "OctopusServicePassword" ($octopusServiceCredential.Password | ConvertFrom-SecureString)
    }
    else {
        Write-Log "Configuring service to run as Local System"
        Update-InstallState "OctopusServiceUsername" $null
        Update-InstallState "OctopusServicePassword" $null
    }
    Invoke-OctopusServerCommand $args

    if (($null -ne $octopusBuiltInWorkerCredential) -and ($octopusBuiltInWorkerCredential -ne [PSCredential]::Empty)) {
        if (Test-OctopusVersionSupportsRunAsCredential) {
            Write-Log "Configuring Octopus Deploy to execute run-on-server scripts as $($octopusBuiltInWorkerCredential.UserName) ..."
            $args = @(
                'builtin-worker',
                '--instance', $name,
                '--username', $octopusBuiltInWorkerCredential.UserName,
                '--password', $octopusBuiltInWorkerCredential.GetNetworkCredential().Password
            )
            Update-InstallState "OctopusRunAsUsername" $octopusBuiltInWorkerCredential.UserName
            Update-InstallState "OctopusRunAsPassword" ($octopusBuiltInWorkerCredential.Password | ConvertFrom-SecureString)
            Invoke-OctopusServerCommand $args
        } else {
            throw "'OctopusBuiltInWorkerCredential' is only supported from Octopus 4.2 and newer."
        }
    }

    Write-Verbose "Octopus Deploy installed!"
}

function Test-TargetResource {
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [Parameter(Mandatory)]
        [string]$Name,
        [ValidateSet("Started", "Stopped", "Installed")]
        [string]$State = "Started",
        [string]$DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer",
        [string]$WebListenPrefix,
        [string]$SqlDbConnectionString,
        [PSCredential]$OctopusAdminCredential,
        [bool]$AllowUpgradeCheck = $true,
        [bool]$AllowCollectionOfUsageStatistics = $true,
        [ValidateSet("UsernamePassword", "Domain", "Ignore")]
        [string]$LegacyWebAuthenticationMode = 'Ignore',
        [bool]$ForceSSL = $false,
        [bool]$HSTSEnabled = $false,
        [Int64]$HSTSMaxAge = 3600, # 1 hour
        [int]$ListenPort = 10943,
        [Nullable[bool]]$AutoLoginEnabled = $null,
        [PSCredential]$OctopusServiceCredential,
        [string]$HomeDirectory = "$($env:SystemDrive)\Octopus",
        [string]$ServerLogsDirectory = "$HomeDirectory\Logs",
        [string]$ServerMetricsDirectory = "$HomeDirectory\Logs",
        [PSCredential]$OctopusMasterKey = [PSCredential]::Empty,
        [string]$LicenseKey = $null,
        [bool]$GrantDatabasePermissions = $true,
        [PSCredential]$OctopusBuiltInWorkerCredential = [PSCredential]::Empty,
        [string]$PackagesDirectory = "$HomeDirectory\Packages",
        [string]$ArtifactsDirectory = "$HomeDirectory\Artifacts",
        [string]$TaskLogsDirectory = "$HomeDirectory\TaskLogs",
        [bool]$LogTaskMetrics = $false,
        [bool]$LogRequestMetrics = $false
    )

    try {
        Test-ParameterSet -Ensure $Ensure `
                          -Name $Name `
                          -State $State `
                          -DownloadUrl $DownloadUrl `
                          -WebListenPrefix $WebListenPrefix `
                          -SqlDbConnectionString $SqlDbConnectionString `
                          -OctopusAdminCredential $OctopusAdminCredential

        # make sure the global is up to date
        $script:instancecontext = $Name

        $currentResource = (Get-TargetResource -Ensure $Ensure `
                -Name $Name `
                -State $State `
                -DownloadUrl $DownloadUrl `
                -WebListenPrefix $WebListenPrefix `
                -SqlDbConnectionString $SqlDbConnectionString `
                -OctopusAdminCredential $OctopusAdminCredential `
                -AllowUpgradeCheck $AllowUpgradeCheck `
                -AllowCollectionOfUsageStatistics $AllowCollectionOfUsageStatistics `
                -LegacyWebAuthenticationMode $LegacyWebAuthenticationMode `
                -ForceSSL $ForceSSL `
                -HSTSEnabled $HSTSEnabled `
                -HSTSMaxAge $HSTSMaxAge `
                -ListenPort $ListenPort `
                -AutoLoginEnabled $AutoLoginEnabled `
                -OctopusServiceCredential $OctopusServiceCredential `
                -HomeDirectory $HomeDirectory `
                -ServerLogsDirectory $ServerLogsDirectory `
                -ServerMetricsDirectory $ServerMetricsDirectory `
                -LicenseKey $LicenseKey `
                -GrantDatabasePermissions $GrantDatabasePermissions `
                -OctopusBuiltInWorkerCredential $OctopusBuiltInWorkerCredential `
                -PackagesDirectory $PackagesDirectory `
                -ArtifactsDirectory $ArtifactsDirectory `
                -TaskLogsDirectory $TaskLogsDirectory `
                -LogTaskMetrics $LogTaskMetrics `
                -LogRequestMetrics $LogRequestMetrics)

        $paramsWhereNullMeansIgnore = @('AutoLoginEnabled')

        $params = Get-ODSCParameter $MyInvocation.MyCommand.Parameters

        $currentConfigurationMatchesRequestedConfiguration = $true
        foreach ($key in $currentResource.Keys) {
            $currentValue = $currentResource.Item($key)
            $requestedValue = $params.Item($key)

            if ($currentValue -is [PSCredential]) {
                if (-not (Test-PSCredential $currentValue $requestedValue)) {
                    Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '********' mismatched the specified value '********'"
                    $currentConfigurationMatchesRequestedConfiguration = $false
                } else {
                    Write-Verbose "Configuration parameter '$key' matches the requested value '********'"
                }
            }
            elseif (($null -eq $requestedValue) -and $paramsWhereNullMeansIgnore.contains($key)) {
                Write-Verbose "Configuration parameter '$key' has value '$currentValue' - requested value not set"
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
    } catch {
        Resolve-Error $_
        throw
    }
}

function Test-PSCredential($currentValue, $requestedValue) {

    if (($null -ne $currentValue) -and ($currentValue -ne [PSCredential]::Empty)) {
        $currentUsername = $currentValue.GetNetworkCredential().UserName
        $currentPassword = $currentValue.GetNetworkCredential().Password
    }
    else {
        $currentUsername = ""
        $currentPassword = ""
    }

    if (($null -ne $requestedValue) -and ($requestedValue -ne [PSCredential]::Empty)) {
        $requestedUsername = $requestedValue.GetNetworkCredential().UserName
        $requestedPassword = $requestedValue.GetNetworkCredential().Password
    }
    else {
        $requestedUsername = ""
        $requestedPassword = ""
    }

    if ($currentPassword -ne $requestedPassword -or $currentUsername -ne $requestedUsername) {
        return $false
    }
    return $true
}

function Test-ParameterSet {
    param (
        [string]$Ensure,
        [string]$Name,
        [string]$State,
        [string]$DownloadUrl,
        [string]$WebListenPrefix,
        [string]$SqlDbConnectionString,
        [PSCredential]$OctopusAdminCredential = [PSCredential]::Empty
    )

    if ([string]::IsNullOrEmpty($Ensure)) {
        throw "Parameter 'Ensure' must be supplied."
    }

    $values = @("Present", "Absent")
    if ($values -notcontains $Ensure) {
        throw "Parameter 'Ensure' had unexpected value '$Ensure'. It should have been one of [$([string]::Join(", ", $values))]."
    }

    if ([string]::IsNullOrEmpty($State)) {
        throw "Parameter 'State' must be supplied."
    }

    $values = @("Started", "Stopped", "Installed")
    if ($values -notcontains $State) {
        throw "Parameter 'State' had unexpected value '$State'. It should have been one of [$([string]::Join(", ", $values))]."
    }

    if ($Ensure -eq "Present") {
        if ([string]::IsNullOrEmpty($DownloadUrl)) {
            throw "Parameter 'DownloadUrl' must be supplied when 'Ensure' is 'Present'."
        }

        if ($State -ne "Installed") {
            if ([string]::IsNullOrEmpty($Name)) {
                throw "Parameter 'Name' must be supplied when 'Ensure' is 'Present'."
            }

            if ([string]::IsNullOrEmpty($WebListenPrefix)) {
                throw "Parameter 'WebListenPrefix' must be supplied when 'Ensure' is 'Present'."
            }

            if ([string]::IsNullOrEmpty($SqlDbConnectionString)) {
                throw "Parameter 'SqlDbConnectionString' must be supplied when 'Ensure' is 'Present'."
            }

            if (($null -eq $OctopusAdminCredential) -or ($OctopusAdminCredential -eq [PSCredential]::Empty)) {
                throw "Parameter 'OctopusAdminCredential' must be supplied when 'Ensure' is 'Present'."
            }
        }
    } elseif ($Ensure -eq "Absent") {
        if ($State -eq "Started") {
            throw "Invalid configuration requested. " + `
                "You have asked for the service to not exist, but also be running at the same time. " + `
                "You probably want 'State = `"Stopped`"."
        }

        if ($State -eq "Installed") {
            throw "Invalid configuration requested. " + `
                "You have asked for the service to not exist, but also be installed at the same time. " + `
                "You probably want 'State = `"Stopped`"."
        }

        if ([string]::IsNullOrEmpty($Name)) {
            throw "Parameter 'Name' must be supplied when 'Ensure' is 'Absent'."
        }

    }
}

function Get-NLogConfig {
    param (
        [string]$Path
    )

    return [xml](Get-Content -Path $Path)
}

function Set-NLogConfig {
    param (
        [xml]$NLogConfig,
        [string]$Target,
        [string]$Destination
    )

    $xml = $NLogConfig.nlog.targets.target | ? {$_.Name -eq $Target}
    
    if ($Target -eq "octopus-log-file") {
        $xml.fileName = "$Destination/OctopusServer-$($env:ComputerName)-$($name).txt"
        $xml.archiveFileName = "$Destination/OctopusServer-$($env:ComputerName)-$($name).{#}.txt"
    }
    if ($Target -eq "octopus-metrics-file") {
        $metrics.fileName = "$Destination/Metrics-$($env:ComputerName)-$($name).txt"
        $metrics.archiveFileName = "$Destination/Metrics-$($env:ComputerName)-$($name).{#}.txt"
    }
}

function Save-NLogConfig {
    param (
        [xml]$NLogConfig,
        [string]$Path
    )

    $NLogConfig.Save($Path)
}
