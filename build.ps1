<#
.SYNOPSIS
    Build system for packer

.EXAMPLE
    .\build.ps1 -Machine server-web -DeleteOldBuild -Only virtualbox -Headless

    Build only virtualbox and vagrant images for the machine defined in './machines/server-web.ps1',
    delete older builds and don't show GUI.
#>
[CmdletBinding()]
param(
    # Name of the machine definition file without extension
    [parameter(Mandatory=$true)]
    [string]$Machine,
    # Delete all build. If not specified existance of previous build output will stop the process.
    [switch]$DeleteOldBuild,
    # Invoke only specified builders
    [ValidateSet("vmware", "virtualbox")]
    [string]$Only,
    # If specified, install without GUI
    [switch]$Headless,
    # Data for hook scripts
    [object]$Data,
    # Wait indefintelly at the end of the installation until user intervention.
    [switch]$WaitOnEnd
)

function main() {
    $ErrorActionPreference = "Stop"
    trap { log ("{0}`n{1}" -f $_, $_.InvocationInfo.PositionMessage) -ExitCode error }

    if ($DeleteOldBuild) { rm ./output/* -r -force -ea ignore }
    init_fs

    log "Starting build at $(get-date)"
    log "Build command line:`n  $build_cmdline`n"

    check_prereq

    . load_machine
    render_machine_template

    run_hooks 'BUILD_START_LIST'
    if ($WaitOnEnd) { out-file $waitfile }
    run_packer
    on_end -NoPackerError
}

function init_fs () {
    mkdir './tmp', $output -ea ignore | out-null
    out-file -Encoding ascii -InputObject $null $logfile
}

function load_machine () {
    log "Loading machine definition script for '$Machine'"

    $m = "${machines}/${Machine}.ps1"
    if (!(Test-Path $m)) { log "Machine file doesn't exist:`n $m" -ExitCode no_machine }
    cp $m "./tmp/__machine.ps1" -force
    . $m; rv m

    if ($OS_IMAGE) {
        gc "./answer_files/$OS_ANSWER_FILE.xml" | % { $_ -replace 'Windows Server 2012 R2 SERVERSTANDARD', $OS_IMAGE  } | sc $build_answerfile
    } else {
        cp "./answer_files/$OS_ANSWER_FILE.xml" $build_answerfile -force
    }
}

function check_prereq() {
    log "Validating packer installation"
    $p = gcm "packer.exe" -ea ignore
    if ($p.Count -eq 0) { log "Packer must be installed and on the PATH. See https://www.packer.io/downloads" -ExitCode prereq }
}

function create_vagrant_metadata() {
    log "Rendering vagrant metadata template"
    $BOX_NAME = "$Machine"
    $BOX_URL = "$BOX_STORE/${Machine}-virtualbox.box"
    $BOX_REVISION = get_revision
    gc $vagrant_metadata | out-string | render | Out-File -Encoding ascii "$output/${Machine}.json"
}

function get_revision() {
    if (gcm svn.exe -ea 0) {
        try {
            $rev = svn info . 2>&1 | sls ^Revision: | out-string
            $rev = $rev.Trim() -split ' '
        } catch {}
        if ($rev) {return $rev[1]}
    }
    if (gcm git.exe -ea 0) {
        $rev = git rev-parse HEAD 2>&1
        if ($rev -notlike '*Not a git repository*') { return $rev }
    }
}

function log {
  [CmdletBinding()]
  param( [parameter(ValueFromPipeline = $true)] [string] $Msg, $ExitCode='')
  begin {
    if ($exitcode) {
        $ErrorActionPreference = "Continue"
        Write-Error $Msg 2>&1 | tee $logfile -Append
        on_end
        exit $ExitCodes[$ExitCode]
    }
  }
  process { $msg | tee $logfile -Append }
}

function run_hooks([string]$HooksListVar) {
    $hooks = Get-Variable $HooksListVar -ea ignore
    if (!$hooks) { return }
    $hooks = $hooks.Value

    $cnt = $hooks.Length
    log "Executing build hooks in $HooksListVar ($cnt)"
    $hooks | % {
        icm -ScriptBlock $_ -ArgumentList $Data -OutVariable out | log
        $last = $out[$out.Count-1]
        if ($last.GetType() -eq [Boolean] -and $last -eq $false) {
            log "Build start hook terminated the build" -ExitCode hook_fail
        }
    }
    log "Finished executing build hooks in $HooksListVar"
}

function on_end([switch]$NoPackerError)
{
    # DO NOT USE log -ExitCode IN THIS FUNCTION [possible infinite recursion]

    if ($NoPackerError) { create_vagrant_metadata }
    run_hooks 'BUILD_END_LIST'
    clean_up

    if ($NoPackerError) { log "Build finished OK" } else { log "Build failed!" }
}

function clean_up()
{
    log "Cleaning up"
    rm ./packer_cache -r -force -ea ignore
    rm ./tmp          -r -force -ea ignore
    rm ./scripts/__waitfile -ea ignore
}

function render() {
    [CmdletBinding()]
    param ( [parameter(ValueFromPipeline = $true)] [string] $s)
    $ExecutionContext.InvokeCommand.ExpandString($s)
}

function render_machine_template()
{
    log "Rendering machine build template"
    $BUILD_NAME = $Machine
    $BUILD_HEADLESS = $Headless.ToString().ToLower()

    $MEMORY = $MEMORY / 1MB
    $DISK   = $DISK / 1MB

    #Due to the bug in some versions of posh can't use hash in expandstring: http://goo.gl/FoYzVl
    # hash works in 5 & 2, doesn't in 4
    $OS_TYPE.GetEnumerator() | % { Set-Variable "OS_TYPE_$($_.Name)" $_.Value }
    gc $build_template | out-string | render | Out-File -Encoding ascii $buildfile

    log "Validating machine build file"
    packer validate $buildfile
    if ($LastExitCode) { log "Machine build template validation failed" -ExitCode template }

}

function run_packer()
{
    log "Building packer command line"
    $pa = @("build","-color=false")
    if ($Only) { $pa += "-only=$Machine-$Only" }
    $pa += $buildfile
    $cmd = "packer $pa"

    log "Executing packer:`n  $cmd`n"
    iex $cmd | log
    if ($LastExitCode) { log "Packer build failed (ExitCode: $LastExitCode)" -ExitCode packer }
}

$ExitCodes = @{
    packer      = 1
    prereq      = 2
    no_machine  = 3
    template    = 4
    hook_fail   = 5
    error       = 9
}

$output           = "./output/$Machine"
$machines         = "./machines"
$build_template   = "build_template.json"
$vagrant_metadata = "vagrant_metadata.json"

$buildfile        = "$output/build.json"
$logfile          = "$output/posher.log"
$waitfile         = './scripts/__waitfile'
$build_cmdline    = $MyInvocation.Line
$build_answerfile = "$output/Autounattend.xml"

main
