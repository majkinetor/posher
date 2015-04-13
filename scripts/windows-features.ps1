param ([string[]] $Features)

if (!$Features) { "No features specified"; exit; }
"Features: $Features"

$Features | % {

    if ($OS_ANSWER_FILE -eq "2012_r2") {
        "Installing: $_"
        Install-WindowsFeature -IncludeAllSubFeature -Name $_
    }

    if ($OS_ANSWER_FILE -eq "81") {
        "Installing: $_"
        Enable-WindowsOptionalFeature -All -Online -FeatureName $_
    }
}


if ($OS_ANSWER_FILE -eq "2012_r2") {
    if ($WINDOWS_FEATURE_PURGE) {
        "Removing unused features"
        Get-WindowsFeature | ? InstallState -eq 'Available' | Uninstall-WindowsFeature -Remove
    }

    "`nInstalled Features:`n"
    Get-WindowsFeature | ? {$_.Installed} | select Name, DisplayName
}
if ($OS_ANSWER_FILE -eq "81") {
    if ($WINDOWS_FEATURE_PURGE) {
        "Removing unused features"
        Get-WindowsOptionalFeature -Online | ? State -eq 'Disabled' |  Disable-WindowsOptionalFeature -Online -Remove
    }

    "`nInstalled Features:`n"
    Get-WindowsOptionalFeature -Online | ? {$_.State -eq 'Enabled'} | select FeatureName
}
