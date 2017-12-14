$moduleName = Split-Path ($PSCommandPath -replace '\.Tests\.ps1$', '') -Leaf
$modulePath = Split-Path $PSCommandPath -Parent
$modulePath = Resolve-Path "$PSCommandPath/../../$moduleName.ps1"
$module = $null

. $modulePath


$prefix = [guid]::NewGuid().Guid -replace '-'

Describe "Get-ODSCParameter" {
            
    $cred = [PSCredential]::Empty
    $desiredConfiguration = @{
        Name                   = 'Stub'
        Ensure                 = 'Present'
        State                  = 'Started'
        WebListenPrefix        = "http://localhost:80"
        SqlDbConnectionString  = "conn-string"
        OctopusAdminCredential = $cred 
    }

    Get-ODSCParameter $desiredConfiguration


}

Describe "Request-File" {


}
    
