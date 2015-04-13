"`n`nFINALIZING SETUP`n`n"

"Removing temporary files"
rm $Env:Windir/TEMP/*,$Env:TMP/* -force -r -ea ignore

#TODO: Mora windows restart
#"Cleaning Windows updates artifacts"
#dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
#if ($LastExitCode) {  restart_run { dism } }

"Defragmenting drive C:"
Optimize-Volume -DriveLetter C

"Purge unallocated disk data"
./sdelete.exe /accepteula -z c:
