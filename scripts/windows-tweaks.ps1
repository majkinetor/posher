param ( [scriptblock] $Features )

function show-args($Name) {
    "    $Name"
    $ParameterList = $Name.Parameters
    foreach ($key in $ParameterList.keys)
    {
        $var = Get-Variable -Name $key -ErrorAction SilentlyContinue;
        if($var) { "        $($var.name) : $($var.value)" }
    }
}

function Explorer-Feature {
    param(
       [switch]$ShowHidden,
       [switch]$ShowSupperHidden,
       [switch]$ShowFileExtensions,
       # Show full folder path in title and address bar
       [switch]$ShowFullPath,
       [switch]$ShowRun,
       [switch]$ShowAdminTools,
       # Add context menu to open Powershell in the folder
       [switch]$PSOpenHere,
       # Disable Windows start page
       [switch]$NoStartPage,
       # Disable automatic tray icon hiding for all profiles
       [switch]$NoAutoTray
    )
    show-args (Get-Command $MyInvocation.InvocationName)

    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    if ($ShowFullPath)       {
        Set-ItemProperty $key FullPath 1
        Set-ItemProperty $key FullPathAddress 1
    }
    if ($ShowHidden)         { Set-ItemProperty $key Hidden 1}
    if ($ShowSupperHidden)   { Set-ItemProperty $key ShowSuperHidden 1}
    if ($ShowFileExtensions) { Set-ItemProperty $key HideFileExt 0 }
    if ($ShowRun)            { Set-ItemProperty $key Start_ShowRun  1 }
    if ($ShowAdminTools)     { Set-ItemProperty $key StartMenuAdminTools 1 }
    if ($PSOpenHere) {
        $pspath = "$PSHome\powershell.exe -Noexit -Nologo"
        $key = "HKLM:\SOFTWARE\Classes\Directory\shell\PSOpenHere"
        New-Item $key -Force | out-null
        Set-Item $key "PowerShell Here"
        New-item "$key\command" -force | out-null
        Set-item "$key\command" "$pspath -Command Set-Location '%L'"
    }
    if ($NoStartPage) { #http://goo.gl/MfzTj6
        $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"
        Set-ItemProperty $key OpenAtLogon 0
    }
    if ($NoAutoTray) {
        Set-ItemProperty  HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer EnableAutoTray 0
    }
}

function CLI-Feature {
    param(
        [switch] $EnableQuickEdit
    )
    show-args (Get-Command $MyInvocation.InvocationName)
    if ($EnableQuickEdit) { Set-ItemProperty HKCU:\Console QuickEdit 1 }
}

function System-Feature {
    param(
        [switch]$NoHibernation,
        [switch]$NoUAC,
        [switch]$NoShutdownTracker,
        [switch]$NoAutoUpdate,
        [switch]$DisableFirewall,
        # Disable password expiration for all users
        [switch]$NoPasswordExpiration,
        # Use Powershell as default shell on Windows Core
        [switch]$SetPoshAsDefault
    )
    show-args (Get-Command $MyInvocation.InvocationName)

    if ($NoHibernation) {
        Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power HiberFileSizePercent 0
        Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power HibernateEnabled 0
    }

    if ($NoUAC) {
        New-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system EnableLUA -PropertyType DWord -Value 0 -Force | out-null
    }

    if ($NoShutdownTracker) {
        New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT' -Name Reliability -Force | out-null
        Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability' ShutdownReasonOn 0
    }

    if ($NoAutoUpdate) {
        $Updates = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings

        if ($Updates.ReadOnly -eq $True) { Write-Error "Cannot update Windows Update settings due to GPO restrictions." }
        else {
            $Updates.NotificationLevel = 1 #Disabled
            $Updates.Save()
            $Updates.Refresh()
        }
    }

    if ($DisableFirewall) { Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled false -PassThru | select Name,Enabled | ft -Autosize }
    if ($NoPasswordExpiration) { net accounts /maxpwage:unlimited }

    if ($SetPoshAsDefault) { ./Set-PoshAsDefault.ps1 }
}

&$Features
