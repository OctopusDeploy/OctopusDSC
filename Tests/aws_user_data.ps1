<powershell>
Write-Output -ForegroundColor green "Bootstrapping machine"

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine

Write-Output "Installing chocolatey"

if ( (Get-Command "choco" -errorAction SilentlyContinue) ) {
    Write-Output "Chocolatey already installed. Skipping."
} else {
    Write-Output "Installing Chocolatey"
    $wc=new-object net.webclient; $wp=[system.net.WebProxy]::GetDefaultProxy(); $wp.UseDefaultCredentials=$true; $wc.Proxy=$wp; iex ($wc.DownloadString('https://chocolatey.org/install.ps1'))
    $env:Path = $env:Path + ";C:\ProgramData\chocolatey\bin"
    [Environment]::SetEnvironmentVariable( "Path", $env:Path, [System.EnvironmentVariableTarget]::Machine )
}

Write-Output "Installing cygwin & cyg-get"
choco install cygwin --allow-empty-checksums --yes
choco install cyg-get --allow-empty-checksums --yes

#hack: https://github.com/chocolatey/chocolatey-coreteampackages/issues/176#issuecomment-212939458
if (-not(Test-Path "c:\tools\cygwin\cygwinsetup.exe")) {
    invoke-webrequest "https://cygwin.com/setup-x86_64.exe" -outfile "c:\tools\cygwin\cygwinsetup.exe"
    Unblock-File "c:\tools\cygwin\cygwinsetup.exe"
}

Write-Output "Configuring rsync & openssh"
$OLD_USER_PATH=[Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
$OLD_MACHINE_PATH=[Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)

cyg-get rsync
cyg-get openssh

$CYG_PATH = "c:\tools\cygwin\;c:\tools\cygwin\bin"
[Environment]::SetEnvironmentVariable("PATH", "${OLD_USER_PATH};${CYG_PATH}", "User")
[Environment]::SetEnvironmentVariable("PATH", "${OLD_MACHINE_PATH};${CYG_PATH}", "Machine")

Write-Output "Setting up winrm"
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

Write-Output "Setting up firewall"
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

Write-Output "Restarting winrm"
net stop winrm
& c:\windows\system32\sc.exe config winrm start= auto
net start winrm

Write-Output "Cygwin configuration complete."
</powershell>
