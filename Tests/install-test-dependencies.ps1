
if (-not (Test-Path "c:\ProgramData\Chocolatey")) {
  echo "##teamcity[blockOpened name='Installing Chocolatey']"

  write-output "Installing Chocolatey"
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Installing Chocolatey']"
}

if (-not (Test-Path "C:\tools\ruby23")) {

  echo "##teamcity[blockOpened name='Install Ruby']"

  choco install ruby --allow-empty-checksums --yes
  if ($LASTEXITCODE -ne 0) { exit 1 }

  refreshenv
  if ($LASTEXITCODE -ne 0) { exit 1 }

  if (-not (Test-Path "c:\temp")) {
    New-Item "C:\temp" -Type Directory | out-null
  }

  Invoke-WebRequest "https://rubygems.org/downloads/rubygems-update-2.6.7.gem" -outFile "C:\temp\rubygems-update-2.6.7.gem"
  & C:\tools\ruby23\bin\gem.cmd install --local C:\temp\rubygems-update-2.6.7.gem
  if ($LASTEXITCODE -ne 0) { exit 1 }
  & C:\tools\ruby23\bin\update_rubygems.bat --no-ri --no-rdoc
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Install Ruby']"

  echo "##teamcity[blockOpened name='Install ServerSpec']"

  echo "running 'C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc'"
  & C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Install ServerSpec']"
}

echo "##teamcity[blockOpened name='Configuring SQL Server']"

Write-host "Determining SQL Server service name"

$serviceName = 'MSSQL$SQLEXPRESS'
$service = Get-Service $serviceName -ErrorAction SilentlyContinue
if ($null -eq $service) {
  $serviceName = "MSSQLSERVER"
}
write-host "Service name is '$serviceName'"

write-output "Configuring SQL Server to allow TCP/IP connections"

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null

$wmi = new-object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer')

# Enable the TCP protocol on the default instance.
$uri = "ManagedComputer[@Name='$($env:computername)']"
$smoObject = $wmi.GetSmoObject($uri)
$instanceName = $smoObject.ServerInstances[0].Name
$tcp = ($smoObject.ServerInstances[0].ServerProtocols | Where-Object {$_.Name -eq "Tcp"});
$tcp.IsEnabled = $true
$tcp.Alter()

Write-Host "Restarting service"
Restart-Service $serviceName -Force

if ($instanceName -ne "SQLEXPRESS") {
  write-output "Adding sql alias to allow logging in as '(local)\SQLEXPRESS' to the actual server at '(local)'"
  # tests are configured to refer to the server at '(local)\SQLEXPRESS'
  $x86 = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
  $x64 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"

  if (-not (test-path -path $x86)) {
      New-Item $x86 | out-null
  }
  if (-not (test-path -path $x64)) {
      New-Item $x64 | out-null
  }

  $TCPAlias = "DBMSSOCN,(local),1433"
  $KeyName = "(local)\SQLEXPRESS"

  $itemProperty = Get-ItemProperty -Path $x86 -Name $KeyName -ErrorAction SilentlyContinue
  if ($null -eq $itemProperty) {
    New-ItemProperty -Path $x86 -Name $KeyName -PropertyType String -Value $TCPAlias | out-null
  }
  $itemProperty = Get-ItemProperty -Path $x64 -Name $KeyName -ErrorAction SilentlyContinue
  if ($null -eq $itemProperty) {
    New-ItemProperty -Path $x64 -Name $KeyName -PropertyType String -Value $TCPAlias | out-null
  }

  Write-Host "Restarting service"
  Restart-Service $serviceName -Force
}
else {
  write-output "Skipping adding sql alias, as the instance name is already '(local)\SQLEXPRESS'."
}

write-output "Granting access to 'NT AUTHORITY\SYSTEM"
write-output " - finding osql.exe"
$versions = @('100', '110', '120', '130', '140')
foreach($version in $versions) {
  $oSqlPath = "C:/Program Files/Microsoft SQL Server/$version/Tools/Binn/osql.exe"
  if (Test-Path $oSqlPath) {
    break;
  }
}
if (-not (Test-Path $oSqlPath)) {
  Write-Host "Unable to find osql.exe!"
  exit 1
}
write-output " - found it at $oSqlPath"

write-output " - creating login for 'NT AUTHORITY\SYSTEM'"
& "$oSqlPath" "-E" "-S" "(local)\SQLEXPRESS" "-Q" "`"CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS`""
if ($LASTEXITCODE -ne 0) {
  write-output " - failed with exit code $LASTEXITCODE"
  exit 1
}
write-output " - adding 'NT AUTHORITY\SYSTEM' to SYSADMIN role"
& "$oSqlPath" "-E" "-S" "(local)\SQLEXPRESS" "-Q" "`"SP_ADDSRVROLEMEMBER 'NT AUTHORITY\SYSTEM','SYSADMIN'`""
if ($LASTEXITCODE -ne 0) {
  write-output " - failed with exit code $LASTEXITCODE"
  exit 1
}

write-output "Configuring SQL Server to mixed mode authentication"
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') '(local)\SQLEXPRESS'
$s.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
$s.Alter()

Restart-Service $serviceName -Force

echo "##teamcity[blockClosed name='Configuring SQL Server']"

echo "##teamcity[blockOpened name='Installing gem bundle']"

# temporary until the base image has the correct version
echo "running 'C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc'"
& C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc
if ($LASTEXITCODE -ne 0) { exit 1 }

Set-Location c:\temp\tests
& C:\tools\ruby23\bin\bundle.bat _1.14.4_ install --path=vendor
if ($LASTEXITCODE -ne 0) { exit 1 }

echo "##teamcity[blockClosed name='Install gem bundle']"

