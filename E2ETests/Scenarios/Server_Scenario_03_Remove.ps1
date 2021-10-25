function Get-CurrentSSLBinding {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
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
                CertificateThumbprint = ($certificateBinding[2] -split "`n" -replace '[^a-zA-Z0-9]', '')[0]
                AppID           = ($certificateBinding[3] -split "`n")[0]
                CertStore       = ($certificateBinding[4] -split "`n")[0]
            }
        }
    }

    return ($certificateBindingsList | Where-Object {($_.AppID.Trim() -eq $ApplicationId) -and ($_.IPPort.Trim() -eq "{0}:{1}" -f "0.0.0.0", $Port) })
}

$certificate = Get-CurrentSSLBinding -ApplicationId "{E2096A4C-2391-4BE1-9F17-E353F930E7F1}" -Port 443

Configuration Server_Scenario_03_Remove
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cOctopusServerSslCertificate "Configure SSL Certificate"
        {
            InstanceName = "OctopusServer"
            Thumbprint = $certificate.CertificateThumbprint
            Ensure = "Absent"
            StoreName = "My"
            Port = 443
        }

        cOctopusServer OctopusServer
        {
            Ensure = "Absent"
            State = "Stopped"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81,https://localhost"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false
        }
    }
}
