param(
    # http://support.microsoft.com/kb/824684
    # https://msdn.microsoft.com/en-us/library/ff357803(v=vs.85).aspx
    [AllowEmptyCollection()]
    [ValidateSet('Application', 'Connector', 'CriticalUpdates', 'DefinitionUpdates', 'DeveloperKits, ', 'FeaturePacks', 'Guidance', 'SecurityUpdates', 'ServicePacks', 'Tools', 'UpdateRollups', 'Updates')]
    [String[]]$Categories,
    [String[]]$KB
)

$cat=@()
if ($Categories) {
    # Split categories on capitals
    $Categories | % { $cat += (($_ -csplit "(?<=.)(?=[A-Z])") -join ' ') }
    if ($cat.Length) { "Update categories ($($cat.Length)): $($cat -join ', ')" }
}
if ($KB.Length) { "Update KBs ($($KB.Length)): $($KB -join ', ')" }

. ./Get-WUInstall.ps1
Get-WUInstall -OutVariable result -IgnoreUserInput -KBArticleID $KB -Category $cat -AcceptAll -IgnoreReboot
if (!$result) {"WARRNING: No updates installed"}

# How Windows Update determines proxy to use
#http://support.microsoft.com/kb/900935

#The Microsoft Windows Update client program requires Microsoft Windows HTTP Services (WinHTTP) to scan for available updates. Additionally, the Windows Update client uses the Background Intelligent Transfer Service (BITS) to download these updates. Microsoft Windows HTTP Services and BITS run independently of Microsoft Internet Explorer. Both these services must be able to detect the proxy server or proxy servers that are available in your particular environment.

# Get-wulist -Category ("critical updates", "security updates") -Title "Security"
#Get-WUInstall -IgnoreUserInput -Category "Security Updates" -AcceptAll -IgnoreReboot
#Get-WUInstall -IgnoreUserInput -KBArticleID "KB2931366" -AcceptAll -IgnoreReboot
#Get-WUInstall -IgnoreUserInput -AcceptAll -IgnoreReboot
#Get-WUInstall -IgnoreUserInput -Category ("Critical Updates", "Security Updates") -NotCategory "Language packs" -AcceptAll -IgnoreReboot

