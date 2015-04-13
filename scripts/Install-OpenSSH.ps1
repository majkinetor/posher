#TODO:
# Fix SSH admin pass in script
# Replace netsh calls with powershell firewall

param(
  [string]$URL = $null,
  [switch]$AutoStart
)

"==> Install OpenSSH"

$ssh_admin_pass   = "D@rj33l1ng"
$ssh_user         = "vagrant"
$ssh_root         = "C:\Program Files\OpenSSH"

#==============================================================================

if (!$URL) { $URL =  "http://www.mls-software.com/files/setupssh-6.7p1-2.exe" }

$is_64bit = [IntPtr]::size -eq 8
$passwd   = "$ssh_root\etc\passwd"
$temp     = "C:\Windows\Temp"
$exeName  = Split-Path $URL -Leaf

"Installing OpenSSH using installer: $exeName"
"Autostart set to $AutoStart"

if (!(Test-Path "$ssh_root\bin\ssh.exe"))
{

    "Downloading from: $URL"

    $wc = new-object system.net.WebClient
    if ($Env:http_proxy) {
        $wc.proxy = [System.Net.WebRequest]::DefaultWebProxy
        "Proxy enabled, override is {0}" -f ($wc.proxy.GetProxy($URL).AbsoluteUri -ne "${Env:http_proxy}/")
    }
    $wc.DownloadFile($URL, "$temp\openssh.exe")
    if (!(Test-Path "$temp\openssh.exe")) { "ERROR: Can't download OpenSSH"; exit 1}
    "Download finished"

    Start-Process "$temp\openssh.exe" "/S /port=22 /privsep=1 /password=$ssh_admin_pass" -NoNewWindow -Wait
}


Stop-Service "OpenSSHd" -Force

"Setting $ssh_user user file permissions"
mkdir -force "C:\Users\$ssh_user\.ssh"

# set permissions
icacls.exe "C:\Users\${ssh_user}" /grant "${ssh_user}:(OI)(CI)F"
icacls.exe "$ssh_root\bin" /grant "${ssh_user}:(OI)RX"
icacls.exe "$ssh_root\usr\sbin" /grant "${ssh_user}:(OI)RX"

"Setting SSH home directories"
(gc $passwd) | % { $_ -replace '/home/(\w+)', '/cygdrive/c/Users/$1' } | sc $passwd

# Set shell to /bin/sh to return exit status
(gc $passwd) | % {$_ -replace '/bin/bash', '/bin/sh' } | sc $passwd

# fix opensshd to not be strict
"Setting OpenSSH to be non-strict"
(gc "$ssh_root\etc\sshd_config") | % {
        $_  -replace 'StrictModes yes',           'StrictModes no' `
            -replace '#PubkeyAuthentication yes', 'PubkeyAuthentication yes' `
            -replace '#PermitUserEnvironment no', 'PermitUserEnvironment yes' `
            -replace '#UseDNS yes',               'UseDNS no' `
            -replace 'Banner /etc/banner.txt',    '#Banner /etc/banner.txt'
      } | sc "$ssh_root\etc\sshd_config"

# use c:\Windows\Temp as /tmp location
"Setting temp directory location"
rm -Force -ErrorAction SilentlyContinue "$ssh_root\tmp"
start "$ssh_root\bin\junction.exe" "/accepteula '$ssh_root\tmp' '$temp'"
icacls.exe "$temp" /grant "${ssh_user}:(OI)(CI)F"

"Setting up SSH environment"
$sshenv = "TEMP=$temp"
if ($is_64bit) {
    # add 64 bit environment variables missing from SSH
    $env_vars = "ProgramFiles(x86)=C:\Program Files (x86)", `
                "ProgramW6432=C:\Program Files", `
                "CommonProgramFiles(x86)=C:\Program Files (x86)\Common Files", `
                "CommonProgramW6432=C:\Program Files\Common Files"
    $sshenv = $sshenv + "`r`n" + ($env_vars -join "`r`n")
}
sc "C:\Users\$ssh_user\.ssh\environment" $sshenv

# configure firewall
Write-Host "Configuring firewall"
netsh advfirewall firewall add rule name="SSHD" dir=in action=allow service=OpenSSHd enable=yes
netsh advfirewall firewall add rule name="SSHD" dir=in action=allow program="$ssh_root\usr\sbin\sshd.exe" enable=yes
netsh advfirewall firewall add rule name="ssh" dir=in action=allow protocol=TCP localport=22

if ($AutoStart) { Start-Service "OpenSSHd" }
