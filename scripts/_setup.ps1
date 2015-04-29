"`n==| Powershell Windows setup started at $(get-date)`n"

$ErrorActionPreference = "Stop"
trap { "!!! ERROR !!!"; $_; exit 1 }

"==| Setting x64 && x32 powershell execution policy"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
C:\Windows\SysWOW64\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Force"

cd A:; ls

if (!(Test-Path ./__machine.ps1)) { throw "Machine variables are not present" }
. ./__machine.ps1

./Set-Proxy.ps1 $PROXY_SERVER $PROXY_OVERRIDE
./Enable-RDP.ps1
./Enable-WinRM.ps1

./Set-VagrantUser.ps1
./Install-OpenSSH.ps1 -AutoStart -URL $INSTALL_OPENSSH_URL

"`n==| Powershell Windows setup completed at $(get-date)"
