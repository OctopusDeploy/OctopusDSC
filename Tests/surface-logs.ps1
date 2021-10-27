Write-Host "##teamcity[blockOpened name='LCM Configuration']"
Get-DscLocalConfigurationManager
Write-Host "##teamcity[blockClosed name='LCM Configuration']"
