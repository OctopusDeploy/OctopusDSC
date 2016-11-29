<powershell>
Write-Output -ForegroundColor green "Bootstrapping machine"

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine

Write-Output "Setting up WinRM"
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

Write-Output "Setting up firewall"
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

Write-Output "Restarting WinRM"
net stop winrm
& c:\windows\system32\sc.exe config winrm start= auto
net start winrm

Write-Output "WinRM configuration complete."
</powershell>
