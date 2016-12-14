<powershell>
Write-Output -ForegroundColor green "Bootstrapping machine"

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine

Write-Output "Creating self signed cert"
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

Write-Output "Setting up WinRM"
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"

Write-Output "Setting up firewall"
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

Write-Output "Restarting WinRM"
net stop winrm
& c:\windows\system32\sc.exe config winrm start= auto
net start winrm

Write-Output "WinRM configuration complete."
</powershell>
