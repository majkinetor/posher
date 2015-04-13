param ( $ProxyServer, $ProxyOverride )

"==| Setting proxy"

if (!$ProxyServer) { "No proxy server defined"; return; }

# Packer bug
if (Test-Path ./proxy.psm) { mv ./proxy.psm ./proxy.psm1 }
Import-Module ./proxy-module.psm1

proxy -Server $ProxyServer -Override $ProxyOverride -Enable 1
proxyc -FromSystem -Register
