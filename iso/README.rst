This folder contains ISO files.
You can copy them here or link them from other directory (including windows shares) using ``mklink`` command.

In Powershell, use `New-SymLink <http://goo.gl/jgW8bH>`_ script::

    $p = "\\storage.mydomain.com\images\win-server-2012\SW_DVD5_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_Core_MLF_X19-05182.ISO"
    New-SymLink $p -SymName $(Split-Path $p -Leaf) -File
