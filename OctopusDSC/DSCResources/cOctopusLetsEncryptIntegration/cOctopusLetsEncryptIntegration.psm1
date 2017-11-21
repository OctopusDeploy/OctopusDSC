function Get-TargetResource()
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$DnsName,
        [Parameter(Mandatory)]
        [string]$RegistrationEmailAddress,
        [Parameter(Mandatory)]
        [bool]$AcceptLetsEncryptTermsOfService,
        [Parameter(Mandatory)]
        [int]$HttpsPort,
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$Path
    )

    $existingEnsure = "Present"
    if ((Get-LetsEncryptConfiguration -ApiKey $ApiKey -DnsName $DnsName).Enabled -eq $false) {
        $existingEnsure = "Absent"
    }

    $result = @{
        Ensure = $existingEnsure
        ApiKey = $ApiKey
        DnsName = $DnsName
        RegistrationEmailAddress = $RegistrationEmailAddress
        AcceptLetsEncryptTermsOfService = $AcceptLetsEncryptTermsOfService
        HttpsPort = $HttpsPort
        IPAddress = $IPAddress
        Path = $Path
    }

    return $result
}

function Set-TargetResource()
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$DnsName,
        [Parameter(Mandatory)]
        [string]$RegistrationEmailAddress,
        [Parameter(Mandatory)]
        [bool]$AcceptLetsEncryptTermsOfService,
        [Parameter(Mandatory)]
        [int]$HttpsPort,
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$Path
    )

    $currentResource = Get-TargetResource -Ensure $Ensure `
        -ApiKey $ApiKey `
        -DnsName $DnsName `
        -RegistrationEmailAddress $RegistrationEmailAddress `
        -AcceptLetsEncryptTermsOfService $AcceptLetsEncryptTermsOfService `
        -HttpsPort $HttpsPort `
        -IPAddress $IPAddress `
        -Path $Path
    
    if ($Ensure -eq "Absent" -and $currentResource.Ensure -eq "Present") {
        Remove-LetsEncryptConfiguration -ApiKey $ApiKey -DnsName $DnsName
    }
    elseif ($Ensure -eq "Present" -and $currentResource.Ensure -eq "Absent") {
        $task = (Add-LetsEncryptConfiguration -ApiKey $ApiKey `
            -DnsName $DnsName `
            -RegistrationEmailAddress $RegistrationEmailAddress `
            -AcceptLetsEncryptTermsOfService $AcceptLetsEncryptTermsOfService `
            -HttpsPort $HttpsPort `
            -IPAddress $IPAddress `
            -Path $Path)
        
        Get-LetsEncryptConfigurationTaskStatus -ApiKey $ApiKey -DnsName $DnsName -Id $task.Id
    }
}

function Test-TargetResource()
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$DnsName,
        [Parameter(Mandatory)]
        [string]$RegistrationEmailAddress,
        [Parameter(Mandatory)]
        [bool]$AcceptLetsEncryptTermsOfService,
        [Parameter(Mandatory)]
        [int]$HttpsPort,
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$Path
    )

    $currentResource = Get-TargetResource -Ensure $Ensure `
        -ApiKey $ApiKey `
        -DnsName $DnsName `
        -RegistrationEmailAddress $RegistrationEmailAddress `
        -AcceptLetsEncryptTermsOfService $AcceptLetsEncryptTermsOfService `
        -HttpsPort $HttpsPort `
        -IPAddress $IPAddress `
        -Path $Path

    $params = Get-OctopusDSCParameter $MyInvocation.MyCommand.Parameters
    
    $currentConfigurationMatchesRequestedConfiguration = $true

    foreach ($key in $currentResource.Keys) {
        $currentValue = $currentResource.Item($key)
        $requestedValue = $params.Item($key)
        if ($currentValue -ne $requestedValue) {
            Write-Verbose "(MISMATCH FOUND) Configuration parameter '$key' with value '$currentValue' mismatched the requested value '$requestedValue'"
            $currentConfigurationMatchesRequestedConfiguration = $false
        }
        else {
            Write-Verbose "Configuration parameter '$key' matches the requested value '$requestedValue'"
        }
    }

    return $currentConfigurationMatchesRequestedConfiguration
}

function Get-LetsEncryptConfiguration()
{
    param (
        [string]$ApiKey,
        [string]$DnsName
    )

    $result = (Invoke-RestMethod -Method "Get" -Headers @{ "X-Octopus-ApiKey" = $ApiKey } -Uri "http://$DnsName/api/letsencryptconfiguration" -UseBasicParsing)
    return $result
}

function Get-LetsEncryptConfigurationTaskStatus()
{
    param (
        [string]$ApiKey,
        [string]$DnsName,
        [string]$Id
    )

    do {
        $task = (Invoke-RestMethod -Method Get -Headers @{ "X-Octopus-ApiKey" = $ApiKey } -Uri "http://$DnsName/api/tasks/$Id/details").Task
        if ($task.State -eq "Failed") {
            throw $task.ErrorMessage
        }

        Start-Sleep -Seconds 10
    }
    while ($task.State -eq "Queued")
}

function Add-LetsEncryptConfiguration()
{
    param (
        [string]$ApiKey,
        [string]$DnsName,
        [string]$RegistrationEmailAddress,
        [bool]$AcceptLetsEncryptTermsOfService,
        [int]$HttpsPort,
        [string]$IPAddress,
        [string]$Path
    )

    $body = @{
        Id = $null
        State = "Queued"
        Name = "ConfigureLetsEncrypt"
        Description = "Configure Let's Encrypt SSL Certificate"
        Arguments = @{
            DnsName = $DnsName
            RegistrationEmailAddress = $RegistrationEmailAddress
            AcceptLetsEncryptTermsOfService = $AcceptLetsEncryptTermsOfService
            HttpsPort = $HttpsPort
            IPAddress = $IPAddress
            Path = $Path
        }
        Links = $null
    } | ConvertTo-Json -Compress

    $result = (Invoke-RestMethod -Method "Post" -Headers @{ "X-Octopus-ApiKey" = $ApiKey } -Uri "http://$DnsName/api/tasks" -Body $body -UseBasicParsing)
    return $result
}

function Remove-LetsEncryptConfiguration()
{
    param (
        [string]$ApiKey,
        [string]$DnsName
    )

    $body = (Get-LetsEncryptConfiguration -ApiKey $ApiKey -DnsName $DnsName)
    $body.Enabled = $false

    $result = (Invoke-RestMethod -Method "Post" -Headers @{ "X-Octopus-ApiKey" = $ApiKey } -Uri "http://$DnsName/api/letsencryptconfiguration" -Body $body -UseBasicParsing)
    return $result
}
