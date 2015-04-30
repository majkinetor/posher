"==| Enable and set WinRM"

# For Vagrant see "Base Windows Machine" at https://docs.vagrantup.com/v2/boxes/base.html

## https://technet.microsoft.com/en-us/library/hh849694.aspx
Enable-PSRemoting -Force #-SkipNetworkProfileCheck

## https://technet.microsoft.com/en-us/library/hh849872.aspx
Enable-WSManCredSSP -Force -Role server
Enable-WSManCredSSP -Force -Role client -DelegateComputer *

# http://blogs.technet.com/b/heyscriptingguy/archive/2013/07/30/learn-how-to-configure-powershell-memory.aspx
# https://technet.microsoft.com/en-us/library/hh847813.aspx

Set-Item WSMan:\localhost\MaxTimeoutms              1800000 -force
Set-Item WSMan:\localhost\Service\AllowUnencrypted  $true   -force
Set-Item WSMan:\localhost\Service\Auth\Basic        $true   -force
Set-Item WSMan:\localhost\Client\Auth\Basic         $true   -force
Set-Item WSMan:\localhost\Listener\*\Port           5985    -force


Get-Item -Path @(
    'WSMan:\localhost\MaxTimeoutms'
    'WSMan:\localhost\Service\AllowUnencrypted'
    'WSMan:\localhost\Service\Auth\Basic'
    'WSMan:\localhost\Client\Auth\Basic'
    'WSMan:\localhost\Listener\*\Port'
    'WSMan:\localhost\Shell\MaxMemoryPerShellMB'
    'WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB'
) | select PSPath, Value | ft -Wrap -Autosize

Test-WSMan

#http://www.hurryupandwait.io/blog/in-search-of-a-light-weight-windows-vagrant-box
#Set-NetFirewallRule -Name WINRM-HTTP-In-TCP-PUBLIC -RemoteAddress Any

#Set-Item WSMAN:\localhost\client\auth\CredSSP $true -force
#set-item wsman:localhost\client\trustedhosts "*" -force

#Import-Module NetSecurity
#New-NetFirewallRule -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -Name "WinRM-In" -DisplayName "WinRM-In" -Group "Windows Remote Management" -Description "Allow inbound tcp port 5985"
#Get-NetFirewallRule -DisplayGroup "Remote Desktop"
#Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#netsh advfirewall firewall set rule group="remote administration" new enable=yes
#if ($LastExitCode) { "ERROR: advfirewall set rule group 'remote administration'" }

#netsh advfirewall firewall add rule name="winrm"  dir=in action=allow protocol=TCP localport=5985
#if ($LastExitCode) { "ERROR: advfirewall add rule name " }
