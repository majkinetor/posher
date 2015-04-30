#
#  DO NOT MODIFY THIS FILE, IT CONTAINS DEFAULT VALUES OF THE BUILD SYSTEM
#  INSTEAD, MODIFY DEFAULTS FROM YOUR OWN SCRIPT THAT SOURCES THIS FILE
#

#ISO file name without extension from ./iso folder. Mandatory.
$OS_ISO_NAME                    = ''

#ISO file SHA1 checksum. Mandatory.
$OS_ISO_CHECKSUM                = ''

#Windows image to install, empty means serverstandard for server and enterprise for workstation.
#Possible values:
#  Windows Server 2012 R2 SERVERSTANDARD
#  Windows Server 2012 R2 SERVERSTANDARDCORE
#  Windows Server 2012 R2 SERVERDATACENTER
#  Windows Server 2012 R2 SERVERDATACENTERCORE
#  Windows 8.1 Pro
#  Windows 8.1 Enterprise
$OS_IMAGE                       = ''

#Answer file file name without extension from ./answer_files folder. Mandatory.
$OS_ANSWER_FILE                 = ''

#Hash containing OS type for providers. Mandatory for best performance.
$OS_TYPE                        = @{vmware='other'; virtualbox='other'}

#Numbert of CPUs
$CPU                            = 1

#Memory size
$MEMORY                         = 2GB

#Disk size
$DISK                           = 60GB

#OpenSSH installer URL. Optional, by default empty which means that internet location is used.
$INSTALL_OPENSSH_URL            = ''

# Proxy server for the administrative user. Optional.
$PROXY_SERVER                   = ''

# Proxy exclusions for the administrative user. Optional.
$PROXY_OVERRIDE                 = ''

# Enable/disable windows update build feature. Optional, on by default.
$WINDOWS_UPDATE                 = $true

# Array of KB numbers for deterministic updates. Optional, empty by default.
$WINDOWS_UPDATE_KB_LIST         = @()

# Array of update categories for non-deterministic updates. Optional, use all categories by default.
$WINDOWS_UPDATE_CATEGORIES_LIST = @()

# Enable/disable windows features installation. Optional, on by default.
$WINDOWS_FEATURE                = $true

# Array of feature names obtained by Get-WindowsFeature (server) or get-WindowsOptionalFeature (workstation)
$WINDOWS_FEATURE_LIST           = @()

# Remove all unused features from the disk
$WINDOWS_FEATURE_PURGE          = $false

# Enable/disable small Windows tweaks. Optional, on by default.
$WINDOWS_TWEAKS                 = $true

# Scriptblock to define tweaks. See ./scripts/windows-tweaks.ps1 for details. Optional, does nothing by default.
$WINDOWS_TWEAKS_SCRIPT          = [scriptblock]{}

# Enable/disable Powershell provision. Optional, on by default.
$PROVISION                      = $true

# Array of scriptblocks to run. Optional, does nothing by default.
$PROVISION_LIST                 = @()

# Enable/disable finalization script
$FINALIZE                       = $true

# Vagrant metadata Description property, visible in <machine_name>.json file of the output. Optional, empty by default.
$BOX_DESCRIPTION                = ''

# Vagrant metadata Version property visible in <machine_name>.json file of the output. Optional, 0 by default.
$BOX_VERSION                    = 0

# Used to craft Vagrant metadata BOX_URL property: BOX_URL = "$BOX_STORE/${Machine}-virtualbox.box". Mandatory.
$BOX_STORE                      = ''

# Array of scriptblocks to be executed on host when build starts. Optional, does nothing by default.
# All scriptblocks in the list receive one argument, passed to build script as 'Data' parameter.
# If the last object the scriptblock returns is of type Boolean and is false, the build terminates.
$BUILD_START_LIST               = @()

# Array of scriptblocks to be executed on host when build ends, even with error. Optional, does nothing by default.
$BUILD_END_LIST                 = @()
