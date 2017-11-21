function Get-TargetResource()
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$DnsName,
        [Parameter(Mandatory)]
        [string]$RegistrationEmailAddress,
        [Parameter(Mandatory)]
        [bool]$AcceptLetsEncryptTermsOfService,
        [Parameter(Mandatory)]
        [string]$HttpsPort,
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$Path
    )

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
        [string]$HttpsPort,
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
        # do something
    }
    elseif ($Ensure -eq "Present" -and $currentResource.Ensure -eq "Absent") {
        New-LetsEncryptConfiguration -ApiKey $ApiKey `
            -DnsName $DnsName `
            -RegistrationEmailAddress $RegistrationEmailAddress `
            -AcceptLetsEncryptTermsOfService $AcceptLetsEncryptTermsOfService `
            -HttpsPort $HttpsPort `
            -IPAddress $IPAddress `
            -Path $Path
    }
}

function Test-TargetResource()
{}

function Get-LetsEncryptConfiguration()
{
    param (
        [string]$ApiKey,
        [string]$DnsName
    )

    $response = (Invoke-RestMethod -Method "Get" -Headers @{ "X-Octopus-ApiKey" = $ApiKey } -Uri "http://$DnsName/api/letsencryptconfiguration" -UseBasicParsing)
    return $response
}

function New-LetsEncryptConfiguration()
{
    param (
        [string]$ApiKey,
        [string]$DnsName,
        [string]$RegistrationEmailAddress,
        [bool]$AcceptLetsEncryptTermsOfService,
        [string]$HttpsPort,
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

    Invoke-RestMethod -Method "Post" -Headers @{ "X-Octopus-ApiKey" = $ApiKey } -Uri "http://$DnsName/api/tasks" -Body $body -UseBasicParsing
}
