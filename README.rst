Posher
======

.. contents::
   :local:

Posher is a build system that generates images for Windows 2012 family of operating systems - all variants of Windows Server 2012 and Windows 8. Machines are defined using Powershell scripts and built using `Packer <https://www.packer.io/>`__.

The main features of the system are:

- Hierarchical machine definition - machine can inherit from another one which serves as a base system and then it can add or tweak options, features and provisioning elements on top of those already defined in the parent machines. The system is made so that all the different types of machines used for specific project can be described and created in this manner while keeping the entire process `DRY <http://en.wikipedia.org/wiki/Don't_repeat_yourself>`__.
- Strict usage of the Powershell scripting rather then outdated cmd.exe shell.
- Extensive auditing of installed options so that one can understand what is inside the machine just by looking in the log file of the build system.
- Support for multiple virtualization platforms via Packer. Currently, the machines are built for vmWare and VirtualBox providers with addition of Vagrant box. Other providers that Packer supports can easily by added if required.

Posher can be used for:

- Creation of referent machines for which developers program desired features. Usage of referent machines solve the *it works on my computer* problem as functionality is considered done if it is successfully deployed and tested on the referent machine(s).
- Using single code base for setting up machines for all types of environments in a service life cycle.
- Creation of immutable infrastructure which is defined and versioned as a source code.


Prerequisites
-------------

- `Windows Management Framework 4.0 <http://www.microsoft.com/en-us/download/details.aspx?id=40855>`_ or newer.
- `Packer <https://www.packer.io/>`__
- `VirtualBox <https://www.virtualbox.org>`__  (if the build type includes VirtualBox output)
- `vmWare Workstation <http://www.vmware.com/products/workstation>`__ (if the build type includes vmware output)
- `Vagrant <https://www.vagrantup.com/>`__ (to test virtualbox boxes)

The easiest way to install all open source prerequisites is via `Chocolatey <https://chocolatey.org>`__ repository::

    choco install packer virtualbox vagrant


Creating machine
----------------

Machines are placed in the ``machines`` directory and described in Powershell syntax. The only input for the machine apart from assets required for provisioning of vendor tools is the ISO image of the desired OS. ISO files can be linked from the Internet, SMB share or locally by placing them into ``iso`` directory (using symbolic link is also an option via ``iso\New-SymLink.ps1`` function).

To start defining a machine in a Powershell, first check `machines\_default.ps1 <https://github.com/majkinetor/posher/blob/master/machines/_default.ps1>`__ which contains all variables supported by the build system and their default values. This file should not be edited - a new Powershell file should be created for each machine which sources aforementioned defaults.

As an example, lets say we want all servers for the service to have some common foundation on which we can further specialise for different roles. We can create ``base-server.ps1`` to describe this configuration::

    . "$PSScriptRoot/_default.ps1"

    $OS_ISO_NAME     = 'SW_DVD5_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_Core_MLF_X19-05182'
    $OS_ISO_CHECKSUM = '6823c34a84d22886baea88f60e08b73001c31bc8'
    $OS_TYPE         = @{vmWare = 'windows8srv-64'; virtualbox = 'Windows2012_64'}
    $OS_ANSWER_FILE  = '2012_r2'

    $WINDOWS_UPDATE                  = $true
    $WINDOWS_UPDATE_CATEGORIES_LIST += 'CriticalUpdates', 'SecurityUpdates'
    #$WINDOWS_UPDATE_KB_LIST        += 'KB2939087'

    $WINDOWS_TWEAKS                  = $true
    $WINDOWS_TWEAKS_SCRIPT = {
        Explorer-Feature -ShowHidden -ShowSupperHidden -ShowFileExtensions -ShowRun -ShowAdminTools -PSOpenHere
        CLI-Feature      -EnableQuickEdit
        System-Feature   -NoUAC -NoHibernation -NoShutDownTracker -NoAutoUpdate
    }

    $WINDOWS_FEATURE = $true
    $WINDOWS_FEATURE_LIST = @(
        "PowerShell-ISE"
    )

This will define the ``base-server`` so that:

- It will use specified ISO image and answer file with the given name ( ``OS_ISO_NAME`` and ``OS_ANSWER_FILE`` variables ).
- The build option ``WINDOWS_UPDATE`` is enabled which means that during OS setup the specified windows updates will be installed. In this example only critical and security updates are installed (variable ``WINDOWS_UPDATE_CATEGORIES_LIST``). The commented option ``WINDOWS_UPDATE_KB_LIST`` is used for deterministic updates as defining updates via category list will produce non-deterministic operating system on which updates are installed as soon as they are available which can potentially create a problem with some applications.
- The build option ``WINDOWS_TWEAKS`` is enabled which is integrated list of small Windows customizations which are self describing in above case. The option accepts single script block which calls 3 functions that tweak OS installation.
- At the end, there is one Windows features that will be installed on the base server - Powershell-ISE.

Later we can either build this base server or create another machine based on it. If, for instance, we need IIS web server on top of the base server definition, we can define the machine ``server-web.ps1`` such as::

    . "$PSScriptRoot/base-server.ps1"

    $CPU    = 4
    $MEMORY = 4GB
    $DISK   = 60GB

    $WINDOWS_FEATURE_LIST += @(
    # Web server modules
        "Web-Common-Http",
        "Web-Security",
    # "Web-App-Dev"
        "Web-CGI",
        "Web-ISAPI-Ext",
        "Web-ISAPI-Filter",
        "Web-Includes",
    # Web Management Tools
        "Web-Mgmt-Console",
        "Web-Scripting-Tools",
        "Web-Mgmt-Service",
    # Dot.Net 4.5
        "NET-Framework-45-ASPNET"
        "NET-Framework-45-Features"
    )

    # Vagrant settings
    $BOX_DESCRIPTION = "IIS web server"
    $BOX_VERSION     = 1.1
    $BOX_STORE       = "file:////itshare.mycompany.com/_images/projectX/projectx-server-web"

In the above example the new server is defined so that it:

- uses specified number of CPUs (default is 1) and desired memory and disk size.
- adds new Windows features to the ``WINDOWS_FEATURE_LIST`` of the already specified features in the base server (hence ``+=``).
- defines few Vagrant related variables - ``BOX_XXX`` -  which may be needed for the development environments with the machine.

Depending on the parameter, the machine can either inherit the parameter value from the parent machine, redefine it, or add it to the existing list. Machines can be defined this way to the arbitrary depth and any machine in the hierarchy can be built by specifying its name as an argument of the build script.

Host and guest provision
------------------------

There is an option to specify provision scriptblock on either the host (the one that builds the image, before or after the image build process is started) or the machine that is being built.

The following machine ``server-web-extra`` inherits from the ``server-web`` and during the build it requires credentials for the share, exports the credentials temporarily to copy and use them within the context of the new machine in order to install the application from the share. At the end of the build it deletes temporary file on the host::

    . "$PSScriptRoot/server-web.ps1"

    #Executes on host
    $BUILD_START_LIST += {
        $err = export_credential $args.Credential -Store './machines' -AskMsg 'Enter credentials for the administrative share:'
        if ($err) { "Credential export failed - $err"; return $false }
    }

    #Executes on host
    $BUILD_END_LIST += {
        "Deleting temporary files on host"
        rm "./machines/*.sss" -ea ignore
    }

    #Executes on guest
    $PROVISION_LIST  += {
        "Loading credentials"
        $f = gi "*.sss"
        $Credential = load_credential $f
        if (!$Credential) { throw "Can't load credentials." }
        rm $f

        New-PSDrive -Name adminshare -PSProvider FileSystem -Root \\itshare.mycompany.com\install -Credential $Credential
        $installer = "adminshare:\ToolXYZ\toolxyz.msi"
        start -Wait msiexec -ArgumentList "/quiet", "ADDLOCAL=ALL", "/i $installer"
        if (Test-Path 'c:\program files\toolxyz\toolxyz.exe) { "Install OK" } else { throw "Install failed" }
    }

    function load_credential($File) {
        if (!$File) { return }
        $u = $File.BaseName.Replace('-', '\')
        $p = ConvertTo-SecureString (gc $File) -Key (1..16)
        New-Object -Type PSCredential -ArgumentList $u, $p
    }

    function export_credential($Credential, $Store, $AskMsg){
        gi $Store -ErrorVariable err -ea 0 | out-null
        if ($err) { return $err }

        if (!$Credential -or $Credential.gettype() -ne [PSCredential]) {
            $Credential = Get-Credential $Credential -Message $AskMsg
            if (!$Credential) { Write-Error "Credential input canceled." -ev err -ea 0; return $err }
        }

        try {
            $fp = "{0}/{1}.sss" -f $Store, $Credential.UserName.Replace('\', '-')
            rm $fp -ea ignore
            ConvertFrom-SecureString -SecureString $Credential.Password -Key (1..16) | out-file $fp
        } catch { $_ }
    }

Options
-------

The build system currently supports the following options that are so commonly tweaked that they deserved to be specially handled:

WINDOWS_UPDATE
    Allows installation of predefined set of updates with desired level of determination. To be totally deterministic specify list of KBs, otherwise specify some of the allowed categories.

WINDOWS_TWEAKS
    Allows for installation of small tweaks from the list of supported tweaks. For the complete list of tweaks see ``scripts\windows-tweaks.ps1``.

WINDOWS_FEATURES
    Enables the list of the Windows features that are shipped with the OS and installed using ``OptionalFeatures.exe`` on a workstation Windows (Control Panel -> Turn Windows Features On or Off) or using Server Manager Roles and Features GUI interface on a server. To get the complete list of features, use the following cmdlets: ``Get-WindowsOptionalFeature`` (workstation) and ``Get-WindowsFeature`` (server).

PROVISION
    Enables the list of provisioning Powershell scriptblocks. Each machine can add its own provisioner in the ``$PROVISION_LIST`` list.

FINALIZE
    Allows finalization script to run. This script cleans up the system, deletes temporary files, defragments and shreds the disk etc. The procedure is lengthy and can be disabled while testing.

Each of those options can be turned on or off using simple Powershell statement. For instance::

    $WINDOWS_UPDATE = $false

will turn off integrated Windows update build option which may be useful during testing as updates usually take a long time to finish.

For detailed description of all options check out comments in the ``machines\_default.ps1`` script.

Build
-----

To generate the virtual image use ``build.ps1`` script::

    .\build.ps1 -Machine server-web

The length of the procedure depends on the machine definition - location of the ISO file, whether Windows updates are enabled and so on. After the build process finishes, the images and log files will be available in the ``output\<mashine_name>`` directory. Detailed log of the complete operation is saved in the file ``posher.log``. Distribution of the machine should include this file because it provides information about the machine installation and any step of the installation starting from the ISO file can be manually reconstructed using the information within the log file and few other files that are also stored in the output folder.

To build the machine only for the specific platform use the build parameter ``Only``::

    .\build.ps1 -Machine server-web -Only virtualbox

Without this parameter build will produce machines for all supported platforms in parallel.

When you try to build above machine with host and guest provisioning ( server-web-extra ), credential pop up will appear on the host and the build continues after the user enters it correctly or fails on any error. To build this machine non-interactively, parameter can be passed to the build script via ``Data`` argument::

    ./build.ps1 -Machine base-server-extra -Data @{ Credential = Get-Credential } -Verbose

If the provisioning code is big, put it in the separate script file in the ``./machines`` directory and source it from the provisioning scriptblock.

For detailed description of the build function execute ``man .\build.ps1 -Full``.

Accessing the machine
---------------------

After the build is completed, you can boot up the VirtualBox image using Vagrant.  ``Vagrantfile`` is designed in such way that you can easily test any local images (those in the ``output`` directory). Quickly switch from using local to remote box storage using ``VAGRANT_LOCAL`` variable. Any machine that is created in ``machines`` directory can be booted this way without modifications of the ``Vagrantfile``::

    vagrant destroy server-web
    vagrant box remove server-web

    $Env:VAGRANT_LOCAL=1
    vagrant up server-web
    vagrant rdp server-web

The last two commands will fire up the machine and connect to it via remote desktop. If something goes wrong and RDP is not working you can set ``$Env:VAGRANT_GUI=1`` to show VirtualBox GUI, otherwise machine will run in the headless mode.

The other way to connect to the machine is via Powershell remoting using its IP address::

    etsn 192.168.0.xx -Credential localhost\vagrant

For this to work the machine IP (or glob ``*``) must be specified in the  ``TrustedHosts`` parameter in the WinRM client settings::

    Set-Item WSMan:\localhost\Client\TrustedHosts * -Force

Once you are happy with the machines those should be deployed to the share. For this purpose Vagrant metadata json is crafted that among other things provides option to version remote boxes so that users can see when those boxes they use are later updated during ``vagrant up`` command. Developers can use those boxes but to provide access to them manual intervention of ``Vagrantfile`` is required to specify exact machine names - simply replace dynamic ruby hash ``$machines`` with static version listing machine names.

To test wmWare images with Vagrant require proprietary Vagrant driver. If those are not available testing can be done with vmWare Workstation command line tools easily, although setting advanced options such as shared folders and customizing memory and disk will require extra work::

    vmrun -T ws start "output\server-web\packer-server-web-vmware.vmx"

On production
-------------

Although one of the design goals of the system was to use the same machine code in the production, test and development environments with any specific configuration moved to environment variables, it is not currently tested in production environments and would at minimal require some security related actions such as removal of vagrant administrative user. Some of the future versions will address those issues.

More info
---------

**Articles**

- `Immutable Server <http://martinfowler.com/bliki/ImmutableServer.html>`__
- `Virtualize Your Windows Development Environments with Vagrant, Packer, and Chocolatey <http://www.developer.com/net/virtualize-your-windows-development-environments-with-vagrant-packer-and-chocolatey-part-1.html>`__
- `In search of a light weight windows vagrant box <http://www.hurryupandwait.io/blog/in-search-of-a-light-weight-windows-vagrant-box>`__

**Related Projects**

- `Packer-Windows <https://github.com/joefitzgerald/packer-windows>`__
- `Boxcutter Windows templates <https://github.com/boxcutter/windows>`__
