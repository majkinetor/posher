"==> Set Vagrant User"

"Install vagrant public key"

if (Test-Path "A:\vagrant.pub")
{
    "Using A:\vagrant.pub"
    mkdir "c:\Users\vagrant\.ssh" -ea ignore
    cp "A:\vagrant.pub" "C:\Users\vagrant\.ssh\authorized_keys"
}
else {
    "Downloading vagrant.pub from github"
    $wc = new-object system.net.WebClient
    if ($Env:http_proxy) {
        $wc.proxy = [System.Net.WebRequest]::DefaultWebProxy
        "Proxy enabled, override is {0}" -f ($wc.proxy.GetProxy($URL).AbsoluteUri -ne "${Env:http_proxy}/")
    }
    $wc.DownloadFile('https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub', 'C:\Users\vagrant\.ssh\authorized_keys')
    if (!(Test-Path 'C:\Users\vagrant\.ssh\authorized_keys')) { "ERROR: Downloading public key failed"; exit 1 }
}

"Vagrant public key installed"

"Disable password expiration for user vagrant"
Get-WmiObject -Class Win32_UserAccount -Filter "name = 'vagrant'"  | Set-WmiInstance -Argument @{PasswordExpires = 0} |  Select Name, PasswordExpires
