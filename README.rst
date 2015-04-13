Posher
======

.. contents::
   :local:

Posher is a build system that generates images for Windows 2012 family of operating systems - all variants of Windows Server 2012 and Windows 8. Machines are defined using Powershell scripts and built using `Packer <https://www.packer.io/>`__.

The main features of the system are:

- Hierarchical machine definition - machine can inherit from another one which serves as a base system and then it can add or tweak options, features and provisioning elements on top of those already defined in the parent machines. The system is made so that all the different types of machines used for specific project can be described and created in this manner while keeping the entire process `DRY <http://en.wikipedia.org/wiki/Don't_repeat_yourself>`__.
- Strict usage of the Powershell scripting rather then outdated cmd.exe shell.
- Extensive auditing of installed options so that one can understand what is inside the machine just by looking in the log file of the build system.
- Support for multiple virtualization platforms via Packer. Currently, the machines are built for vmWare and VirtualBox providers with addition of Vagrant box. Other providers that Packer supports can easily by added.

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


Creating Machine
----------------

Machines are placed in the ``machines`` directory and described in Powershell syntax. The only input for the machine apart from assets required for provisioning of vendor tools is the ISO image of the desired OS. ISO files can be linked from Internet, SMB share or locally by placing them into ``iso`` directory (using symbolic link is also an option via ``iso\New-SymLink.ps1`` function).

The start defining a machine in Powershell, first check `machines\_default.ps1 <https://github.com/majkinetor/posher/blob/master/machines/_default.ps1>`__ which contains all variables supported by the build system and their default values. This file should not be edited - a new Powershell file should be created for each machine which sources aforementioned defaults.

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
        "PowerShell", "PowerShell-ISE",
        "NET-Framework-45-Core"
    )

This will define the ``base-server`` so that:

- It will use specified ISO image and answer file with the given name ( ``OS_ISO_NAME`` and ``OS_ANSWER_FILE`` variables ).
- The build option ``WINDOWS_UPDATE`` is enabled which means that during OS setup the specified windows updates will be installed. In this example only critical and security updates are installed (variable ``WINDOWS_UPDATE_CATEGORIES_LIST``). The commented option ``WINDOWS_UPDATE_KB_LIST`` is used for deterministic updates as defining updates via category list will produce non-deterministic operating system on which updates are installed as soon as they are available which can potentially create a problem with some applications.
- The build option ``WINDOWS_TWEAKS`` is enabled which is integrated list of small Windows customizations which are self describing in above case. The option accepts single script block which calls 3 functions that tweak OS installation.
- At the end, there are few Windows features that will be installed on the base server - Powershell and Net-Framework-Core.

Later we can either build this base server or create another machine based on it. If, for instance, we need IIS web server on top of the base server definition, we can define the machine ``server-web.ps1`` such as::

    . "$PSScriptRoot/base-server.ps1"

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

In above example we add new Windows features to the list ``WINDOWS_FEATURE_LIST`` of the already specified features in the base server (hence ``+=``). ``BOX_XXX`` variables are related to the Vagrant box generation for machine testing and development environments.

Depending on the option in question, machine can inherit the option, redefine it, or add it to the existing list of options. The machines can be defined this way to arbitrary depth and any machine in hierarchy can bu built by specifying its name as an argument to the build function.

The build system currently supports the following options that are so commonly tweaked that they deserved to be specially handled:

WINDOWS_UPDATE
    Allows insttallation of predefined set of updated with desired level of determination. To be totally deterministic specify list of KBs, otherwise specify some of the allowed categories.

WINDOWS_TWEAKS
    Allows for installation of small tweaks from the list of supported tweaks. For complete list of tweaks see ``scripts\windows-tweaks.ps1``.

WINDOWS_FEATURES
    List of Windows features that are shipped with OS and installed using ``OptionalFeatures.exe`` on workstation Windows (Control Panel -> Turn Windows Features On or Off) or using Server Manager Roles and Features GUI interface on server. To get the complete list of features using the following cmdlets: ``Get-WindowsOptionalFeature`` (workstation) and ``Get-WindowsFeature`` (server).

PROVISION
    A list of provisioning Powershell scriptblocks. Each machine can add its own provisioner here.

Each of those options can be turned on or off using simple Powershell statement. For instance::

    $WINDOWS_UPDATE = $false

will turn off integrated Windows Update build option which may be useful during testing as updates usually take a long time to finish.

For detailed description of all options check out comments in the ``machines\_default.ps1`` script.

Build
-----

To generate the virtual image use ``build.ps1`` script::

    .\build.ps1 -Machine server-web

The length of the procedure depends on machine definition - location of ISO file, whether Windows updates are enabled and so on. After the build process finishes, the images and log files will be put in the ``output\<mashine_name>`` directory. Very detailed log of complete operation will be saved in the file ``packer.log``. Distribution of the machine should include this file because it provides information about the machine installation and any step of the installation starting from the ISO file can be manually reconstructed using the information within log file and few other files that are also stored in the output folder.

To build machine only for specific platform use build parameter ``Only``::

    .\build.ps1 -Machine server-web -Only virtualbox

Without this parameter build will produce machines for all supported platforms.

If machine definition includes its own provisioners, it can use ``Data`` build option to pass arguments to it (such as credentials required for installation of 3thd party tools and so on).

For detailed description of the build function execute ``man .\build.ps1 -Full``.

After the build is completed, you can test the VirtualBox images using Vagrant (wmWare testing requires proprietary Vagrant driver). ``Vagrantfile`` is designed in such way that you can easily add new local machines for testing and switch from using local to remote box storage using ``VAGRAT_LOCAL`` variable::

    vagrant destroy server-web
    vagrant box remove server-web

    $Env:VAGRANT_LOCAL=1; vagrant up server-web


More info
---------

**Articles**

- `Immutable Infrastructure <http://martinfowler.com/bliki/ImmutableServer.html>`__
- `Virtualize Your Windows Development Environments with Vagrant, Packer, and Chocolatey <http://www.developer.com/net/virtualize-your-windows-development-environments-with-vagrant-packer-and-chocolatey-part-1.html>`__
- `In search of a light weight windows vagrant box <http://www.hurryupandwait.io/blog/in-search-of-a-light-weight-windows-vagrant-box>`__

**Related Projects**

- `Packer-Windows <https://github.com/joefitzgerald/packer-windows>`__
- `Boxcutter Windows templates <https://github.com/boxcutter/windows>`__
