"`n==| Powershell provision"
# Packer vars:
#   $Env:PACKER_BUILDER_TYPE
#   $Env:PACKER_BUILDER_NAME

$ErrorActionPreference = "Stop"
trap { "!!! ERROR !!!"; $_; exit 1 }

function i( $Option, [scriptblock] $Action) {
    $out = { $b = '-' * ($msg.Length+1); ".  $b"; "==| $msg"; ".  $b"  }
    $var = Get-Variable $Option -ea ignore
    if ($var.Value) {
        $msg = "INSTALLING '$Option'"; & $out
        icm -ScriptBlock $Action
    } else { $msg = "OPTION '$Option' IS DISABLED!"; & $out }
}

cd c:\scripts; ls

if (!(Test-Path ./__machine.ps1)) { throw "Machine variables are not present" }
. ./__machine.ps1

cat c:/packer.log; rm c:/packer.log
./Install-GuestAdditions.ps1

#====================================

i 'WINDOWS_FEATURE' { ./windows-features.ps1 $WINDOWS_FEATURE_LIST }
i 'WINDOWS_TWEAKS'  { ./windows-tweaks.ps1 $WINDOWS_TWEAKS_SCRIPT }

i 'PROVISION' {
    if (!$PROVISION_LIST.Length) { "Nothing to provision, list is empty"; return; }
    else { "List contains $($PROVISION_LIST.Length) provisioners`n" }

    $PROVISION_LIST | % {$i=0} {
        "Executing provisioner {0}" -f $i++
        & $_
    }
}

i 'WINDOWS_UPDATE'  { ./windows-update.ps1 $WINDOWS_UPDATE_CATEGORIES_LIST $WINDOWS_UPDATE_KB_LIST}

$waitfile = 'c:\scripts\__waitfile'
if ( Test-Path $waitfile ) {
    "Installation is over. Kill notepad to continue: ps notepad | kill"
    start -Wait notepad.exe
}

i 'FINALIZE' { ./finalize.ps1 }

"==| Powershell provision finished"
