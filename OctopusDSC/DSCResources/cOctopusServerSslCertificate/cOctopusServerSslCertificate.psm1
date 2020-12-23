function Get-CurrentSSLBinding
{

    param([string] $ApplicationId,
    [string]$Port)

    $certificateBindings = (& netsh http show sslcert) | select-object -skip 3 | out-string
    $newLine = [System.Environment]::NewLine
    $certificateBindings = $certificateBindings -split "$newLine$newLine"
    $certificateBindingsList = foreach ($certificateBinding in $certificateBindings) {
        if ($certificateBinding -ne "") {
            $certificateBinding = $certificateBinding -replace "  ", "" -split ": "
            [pscustomobject]@{
                IPPort          = ($certificateBinding[1] -split "`n")[0]
                CertificateHash = ($certificateBinding[2] -split "`n" -replace '[^a-zA-Z0-9]', '')[0]
                AppID           = ($certificateBinding[3] -split "`n")[0]
                CertStore       = ($certificateBinding[4] -split "`n")[0]
            }
        }
    }

    return ($certificateBindingsList | Where-Object {($_.AppID.Trim() -eq $ApplicationId) -and ($_.IPPort.Trim() -eq "{0}:{1}" -f "0.0.0.0", $Port) })
}

function Get-TargetResource
{
    param (
        [string] $InstanceName,
        [string] $Ensure = "Present",
        [string] $Thumbprint,
        [string] $Store,
        [string] $Port,
        [string] $HostName
    )

    $existingConfiguration = Get-ServerConfiguration $InstanceName

    if ($existingConfiguration.ListenPrefixes.ToLower() -contains "https://")
    {
        $existingEnsure = "Present"
        $existingHTTPSPrefixes = ($existingConfiguration.ListenPrefixes.Split(";") | Where-Object {$_.ToLower().BeginsWith("https://")})
    }
    else 
    {
        $existingEnsure = "Absent"    
    }

    $existingSSLConfig = (Get-CurrentSSLBinding -ApplicationId "{E2096A4C-2391-4BE1-9F17-E353F930E7F1}" -Port $Port -IPAddress $IPAddress)

    if ($null -ne $existingSSLConfig)
    {
        $existingSSLPort = [int](($existingSSLConfig.IPPort).Split(":")[1])
        $existingSSLThumbprint = $existingSSLConfig.CertificateHash.Trim()
        $existingSSLCertificateStoreName = $existingSSLConfig.CertStore.Trim()
    }

    $result = @{
        InstanceName    = $Name
        Ensure          = $existingEnsure
        HostNames       = $existingHTTPSPrefixes -join ";"
        Port            = $existingSSLPort
        Store           = $existingSSLCertificateStoreName
        Thumbprint      = $existingSSLThumbprint
    }

    return $result
}

function Test-TargetResource
{
    param(
        [string] $InstanceName,
        [string] $Ensure = "Present",
        [string] $Thumbprint,
        [string] $Store,
        [string] $Port,
        [string] $HostName
    )

    $currentResource = (Get-TargetResource @PSBoundParameters)

    $currentConfigurationMatchesRequestedConfiguration = $true
    foreach ($key in $currentResource.Keys) {
        $currentValue = $currentResource.Item($key)
        $requestedValue = $params.Item($key)

        if ($currentValue -ne $requestedValue) {
            Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '$currentValue' mismatched the specified value '$requestedValue'"
            $currentConfigurationMatchesRequestedConfiguration = $false
        }
        else {
            Write-Verbose "Configuration parameter '$key' matches the requested value '$requestedValue'"
        }
    }

    return $currentConfigurationMatchesRequestedConfiguration
}

function Set-TargetResource
{
    param(
        [string] $InstanceName,
        [string] $Ensure = "Present",
        [string] $Thumbprint,
        [string] $Store,
        [string] $Port,
        [string] $HostName
    )

    $existingConfiguration = Get-ServerConfiguration $InstanceName

    $exeArgs = @(
        'ssl-certificate',
        '--instance', $Instancename,
        '--thumbprint', $Thumbprint,
        '--certificate-store', $Store,
        '--port', $Port
    )
    
    Invoke-OctopusServerCommand $exeArgs

    $sslEntry = ("https://{0}:{1}" -f $HostName, $Port)

    if ($Ensure = "Present")
    {
        $existingConfiguration.WebPrefixes += $sslEntry
    }
    else 
    {
        $sslEntries = $existingConfiguration.WebPrefixes.Split(";")
        $sslEntries = ($sslEntries | Where-Object -ne $sslEntry)
        $existingConfiguration.WebPrefixes = ($sslEntries -join ";")
    }

    $exeArgs = @(
        'configure',
        '--webPrefixes', $existingConfiguration.WebPrefixes
    )

    Invoke-OctopusServerCommand $exeArgs
}

