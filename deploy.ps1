param(
    # Machine name to copy to the Windows share
    # Storage is taken from the machine Metadata
    [string]$Machine
)

$ErrorActionPreference = "Stop"

if (!(ls output\$Machine\*.box -ea ignore)) { throw "Invalid machine" }

# Determine storage from the machine metadata
$meta = ls output\$Machine\$Machine.json | gc
$url = $meta -match '"url"'
$store = $url -split '////' | select -Last 1
$store = $store -split "/$machine" | select -First 1
$store = "\\" + $store.Replace('/', '\')

"Deploying machine: $machine"
"Using store:`n  $store"

$local      = "./output/$machine"
$remote     = "$store/$machine"
$remote_tmp = "$remote-tmp"

try {
    cp -force -r -Verbose $local $remote_tmp
    rm $remote -r -force
    mv $remote_tmp $remote
    "Deploy OK"
} catch {
    "Deploy failed"
    $_
    rm $remote_tmp  -r -force -ea ignore
    exit 1
}

"Deploy finshed"

