# On Windows Core cmd.exe is default shell :S. Change it to Powershell.

$definition = @"
    using System;
    using System.Runtime.InteropServices;
    namespace Win32Api
    {
        public class NtDll
        {
            [DllImport("ntdll.dll", EntryPoint="RtlAdjustPrivilege")]  
            public static extern int RtlAdjustPrivilege(ulong Privilege, bool Enable, bool CurrentThread, ref bool Enabled); 
        }
    }
"@
Add-Type -TypeDefinition $definition -PassThru
$bEnabled = $false

# Enable SeTakeOwnershipPrivilege
$res = [Win32Api.NtDll]::RtlAdjustPrivilege(9, $true, $false, [ref]$bEnabled)

# Take ownership of the registry key
$key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\AlternateShells', [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::takeownership)
$acl = $key.GetAccessControl()
$acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")

# Set Full Control for Administrators
$rule = New-Object System.Security.AccessControl.RegistryAccessRule("Administrators","FullControl", "Allow")
$acl.AddAccessRule($rule)
[void]$key.SetAccessControl($acl)

# Create Registry Value
[void][Microsoft.Win32.Registry]::SetValue($key, "90000", 'powershell.exe -noexit -command "& {set-location $env:userprofile; clear-host}"')
