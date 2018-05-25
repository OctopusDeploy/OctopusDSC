$dbargs = @("database", 
    "--instance", "OctopusServer",
    "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200",
    "--masterKey", "ABCD123456ASDBD")
$pwargs = @("database",
    "--instance", "OctopusServer",
    "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;username=sa;password=p@ssword1234!")
$lcargs = @("license",
    "--console",
    "--instance", "OctopusServer",
    "--licenseBase64", "khsandvlinfaslkndsafdvlkjnvdsakljnvasdfkjnsdavkjnvfwq45o3ragoahwer4")
$npkargs = @("database",
    "--instance", "OctopusServer",
    "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;")



$pwargs -replace "(password|pwd)=[^;]*", "password=********" 

Function Get-MaskedOutput
{
    [CmdletBinding()]
    param($arguments)

    if(($arguments -match "--masterkey|--password|--license") -gt 0)
    {
        # handles cases for --license, --password, --masterkey
        Write-Verbose "We found a sensitive command line argument. Masking"

        # loop the array, find the culprit indexes
        for($x=0;$x -lt $arguments.count; $x++)
        {
            if(($arguments[$x] -match "--masterKey|--password|--license") -gt 0)
            {
                $arguments[$x+1] = $arguments[$x+1] -replace "\w", "*"
            }
        }
        $out = $arguments
    }
    elseif(($arguments -match "password|pwd") -gt 0)
    {
        # handles the password in SQL connection strings
        Write-Verbose "We found a SQL connection string. Masking"

        # do a regex replace for "password=*[;|$]"
        $out = $arguments -replace "(password|pwd)=[^;]*", "password=********" 
    }
    else
    {
        # mask the entire line because we don't know how to handle this. not sure if this is needed
        Write-Verbose "We found sensitive data but unable to selectively mask"
        $out = @("************************")
    }
    return $out
}

<#
Get-MaskedOutput $pwargs -verbose

Get-MaskedOutput $dbargs -verbose

Get-MaskedOutput $lcargs -verbose
#>

function Invoke-OctopusServerCommand ($arguments) {
    if
    ( 
        (($arguments -match "masterkey|password|license").Count -eq 0) 
    )
    {
        Write-Verbose "Executing command '$octopusServerExePath $($arguments -join ' ')'"
    }
    else
    {
        Write-Verbose (Get-MaskedOutput $arguments)
    }
    $output = .$octopusServerExePath $arguments

    Write-CommandOutput $output
    if (($null -ne $LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
        Write-Error "Command returned exit code $LASTEXITCODE. Aborting."
        exit 1
    }
    Write-Verbose "done."
}

Describe "Invoke-OctopusServerCommand" {
    Context "It should not leak password or masterkey" {
        $OctopusServerExePath = "echo" 
        Write-Output "Mocked OctopusServerExePath as $OctopusServerExePath"
        Mock Write-Verbose {  } -verifiable -parameterfilter { $message -like "Executing command*" }
        Function Write-CommandOutput {}
        Mock Get-MaskedOutput {} -Verifiable

        $dbargs = @("database", 
            "--instance", "OctopusServer",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200",
            "--masterKey", "ABCD123456ASDBD")
        $pwargs = @("database",
            "--instance", "OctopusServer",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;username=sa;password=p@ssword1234!")
        $lcargs = @("license",
            "--console",
            "--instance", "OctopusServer",
            "--licenseBase64", "khsandvlinfaslkndsafdvlkjnvdsakljnvasdfkjnsdavkjnvfwq45o3ragoahwer4")
        $npkargs = @("database",
            "--instance", "OctopusServer",
            "--connectionstring", "Data Source=mydbserver;Initial Catalog=Octopus;Integrated Security=SSPI;Max Pool Size=200;")

        It "Doesn't try to mask output when no sensitive values exist " {
            Invoke-OctopusServerCommand $npkargs
            Assert-MockCalled Get-MaskedOutput -times 0
        }

        It "Tries to mask the master key" {
            Invoke-OctopusServerCommand $dbargs
            Assert-MockCalled Get-MaskedOutput
        }

        It "Tries to mask the Connectionstring password" {
            Invoke-OctopusServerCommand $pwargs
            Assert-MockCalled Get-MaskedOutput
        }

        It "Tries to mask the licencebase64" {
            Invoke-OctopusServerCommand $lcargs
            Assert-MockCalled Get-MaskedOutput
        }

        It "Should successfully mask the SQL password" {
            ((Get-MaskedOutput $pwargs) -match "p@ssword1234!").Count | Should be 0
        }

        It "Should successfully mask the licence key" {
            $licence = "khsandvlinfaslkndsafdvlkjnvdsakljnvasdfkjnsdavkjnvfwq45o3ragoahwer4"
            ((Get-MaskedOutput $lcargs) -match $licence).Count | Should Be 0
        }

        It "Should successfully mask the master key" {
            ((Get-MaskedOutput $dbargs) -match "ABCD123456ASDBD").Count | Should Be 0
        }
    }
}