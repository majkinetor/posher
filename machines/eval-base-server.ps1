. "$PSScriptRoot/_default.ps1"

# http://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVER_EVAL_EN-US-IRM_SSS_X64FREE_EN-US_DV5.ISO
$OS_ISO_NAME     = '9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVER_EVAL_EN-US-IRM_SSS_X64FREE_EN-US_DV5'
$OS_ISO_CHECKSUM = '7e3f89dbff163e259ca9b0d1f078daafd2fed513'
$OS_TYPE         = @{vmWare = 'windows8srv-64'; virtualbox = 'Windows2012_64'}
$OS_ANSWER_FILE  = '2012_r2'


$WINDOWS_UPDATE = $true
#$WINDOWS_UPDATE_CATEGORIES_LIST += 'CriticalUpdates', 'SecurityUpdates'
$WINDOWS_UPDATE_KB_LIST += 'KB2939087'

$WINDOWS_TWEAKS = $true
$WINDOWS_TWEAKS_SCRIPT = {
    Explorer-Feature -ShowHidden -ShowSupperHidden -ShowFullPath -ShowFileExtensions -ShowRun -ShowAdminTools -PSOpenHere
    CLI-Feature      -EnableQuickEdit
    System-Feature   -NoUAC -NoHibernation -NoShutDownTracker -NoAutoUpdate
}


