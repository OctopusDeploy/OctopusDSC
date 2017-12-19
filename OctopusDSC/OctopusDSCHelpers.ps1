# Module contains shared code for OctopusDSC

$octopusServerExePath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"
function Get-ODSCParameter($parameters) {
    # unfortunately $PSBoundParameters doesn't contain parameters that weren't supplied (because the default value was okay)
    # credit to https://www.briantist.com/how-to/splatting-psboundparameters-default-values-optional-parameters/
    $params = @{}
    foreach ($h in $parameters.GetEnumerator()) {
        $key = $h.Key
        $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
        if ($null -ne $var) {
            $val = Get-Variable -Name $key -ErrorAction Stop  | Select-Object -ExpandProperty Value -ErrorAction Stop
            $params[$key] = $val
        }
    }
    return $params
}

function Invoke-WebClient($url, $OutFile) {
    $downloader = new-object System.Net.WebClient
    $downloader.DownloadFile($url, $OutFile)
}

function Request-File {
    [CmdletBinding()]
    param (
        [string]$url,
        [string]$saveAs
    )

    $retry = $true
    $retryCount = 0
    $maxRetries = 5
    $downloadFile = $true

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12, [System.Net.SecurityProtocolType]::Tls11, [System.Net.SecurityProtocolType]::Tls

    Write-Verbose "Checking to see if we have an installer at $saveas"
    if(Test-Path $saveAs)
    {
        # check if we already have a matching file on disk
        Write-Verbose "Local file exists"
        $localHash = Get-FileHash $saveAs -Algorithm SHA256 | Select -Expand hash
        Write-Verbose "Local SHA256 hash: $localHash"
        $remoteHash = (Invoke-WebRequest -uri $url -Method Head -UseBasicParsing | select -expand headers).GetEnumerator()  | ? { $_.Key -eq "x-amz-meta-sha256" } | select -expand value
        Write-Verbose "Remote SHA256 hash: $remoteHash"
        $downloadFile = ($localHash -ne $remoteHash)
    }
    else
    {
        Write-Verbose "No local installer found"
    }

    if($downloadFile)
    {
        while ($retry) {
            Write-Verbose "Downloading $url to $saveAs"

            try {
                Invoke-WebClient -Url $url -OutFile $saveAs
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
    else
    {
        Write-Verbose "Local file and remote file hashes match. We already have the file, skipping download."
    }
}

function Invoke-AndAssert {
    param ($block)
    & $block | Write-Verbose
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "Command returned exit code $LASTEXITCODE"
    }
}

function Write-Log {
    param (
        [string] $message
    )

    $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
    Write-Verbose "[$timestamp] $message"
}

function Invoke-OctopusServerCommand ($arguments) {
    Write-Verbose "Executing command '$octopusServerExePath $($arguments -join ' ')'"
    $output = .$octopusServerExePath $arguments

    Write-CommandOutput $output
    if (($null -ne $LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
        Write-Error "Command returned exit code $LASTEXITCODE. Aborting."
        exit 1
    }
    Write-Verbose "done."
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

function Get-ServerConfiguration($instanceName) {
    $rawConfig = & $octopusServerExePath show-configuration --format=json-hierarchical --noconsolelogging --console --instance $instanceName
    $config = $rawConfig | ConvertFrom-Json
    return $config
}

function Get-TentacleConfiguration($instanceName)
{
  $rawConfig = & $tentacleExePath show-configuration --instance $instanceName
  $config = $rawConfig | ConvertFrom-Json
  return $config
}