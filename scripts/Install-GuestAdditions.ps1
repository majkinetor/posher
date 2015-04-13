param(
    [string]$User="vagrant",

    [ValidateSet('vmWare', 'VirtualBox')]
    [string]$Type
    )

if (!$Type) {
    $Type = $Env:PACKER_BUILDER_TYPE -replace '-iso', ''
}

"==> Installing Guest Additions for $Type"

switch($Type) {
    'vmWare'     {$image = "C:\Users\${User}\windows.iso"}
    'VirtualBox' {$image = "C:\Users\${User}\VBoxGuestAdditions.iso"}
}

"Using: $image"
if (!(Test-Path $image)) { throw "ERROR: Can't find guest additions: $image" }

$iso = Mount-DiskImage $image -PassThru
pushd "$((Get-Volume -DiskImage $iso).DriveLetter):"
ls

switch($Type) {
    'vmWare' {
        start -Wait ./setup.exe -ArgumentList '/S /v "/qn REBOOT=R ADDLOCAL=ALL"'       #http://goo.gl/TOZJYT

        if (!(gsv VMTools -ea ignore)) { throw "ERROR: Installation failed - service not running" }
    }
    'VirtualBox' {

        # To prevent user intervention popups which will undermine a silent installation.
        "Setting Oracle certificate"
        $cert = "A:\oracle-cert.cer"
        if (!(Test-Path $cert)) { throw "ERROR: Can't find Oracle certificate"; }
        certutil.exe -addstore -f "TrustedPublisher" $cert

        start -Wait ./VBoxWindowsAdditions.exe -ArgumentList '/S'
        if (!(Test-Path 'C:\Program Files\Oracle\VirtualBox Guest Additions')) { throw "ERROR: Installation failed" }
    }
}

popd
Dismount-DiskImage $image
rm $image
"Guest Additions installed"
