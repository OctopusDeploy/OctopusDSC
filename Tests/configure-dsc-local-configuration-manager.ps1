
$fileContent = @"
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            ConfigurationMode = 'ApplyOnly'
        }
    }
}
"@

Set-Content -Path "c:\temp\lcmconfig.ps1" -Value $fileContent

. "c:\temp\lcmconfig.ps1"

cd "c:\temp"
LCMConfig -OutputPath c:\temp

Set-DscLocalConfigurationManager -Force -Verbose -Path c:\temp
del c:\temp\localhost.meta.mof
