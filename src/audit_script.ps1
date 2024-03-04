# Audit Script: Automated Windows Audit Mode
# Author: github.com/admarty
# Licensed under the GPL-3.0 License
# Copyright © 2023-2024 admarty <long025722@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.


# Check the value of AuditBoot
$auditBoot = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status" -Name "AuditBoot"). "AuditBoot"

# Execute only when in audit mode
if ($auditBoot -ne 0) {
    $ErrorActionPreference = "SilentlyContinue"

    # Import audit_mode_tweak registry key
    reg import "$env:ProgramData\audit_mode_tweak.reg"
    rm "$env:ProgramData\audit_mode_tweak.reg"

    # Disable hibernate
    powercfg /h off

    # Allow incoming IPv4 Ping
    netsh advfirewall firewall add rule name="Allow incoming IPv4 echo requests" protocol=icmpv4:8,any dir=in action=allow

    # Allow incoming IPv6 Ping
    netsh advfirewall firewall add rule name="Allow incoming IPv6 echo requests" protocol=icmpv6:128,any dir=in action=allow


    # Silently install essential apps
    if (Test-Path "$env:ProgramData\apps") {

        # Windows Terminal for Win10
        if (Test-Path "$env:ProgramData\apps\Dependencies") {
            $Terminal = dir "$env:ProgramData\apps\*Terminal*.msix" | Select-Object -Exp FullName
            $UI_Xaml_8 = dir "$env:ProgramData\apps\Dependencies\*UI.Xaml_8*.msix" | Select-Object -Exp FullName
            Add-AppxProvisionedPackage -Online -SkipLic -Reg all -PackagePath $Terminal -Depend $UI_Xaml_8 | Out-Null
        }

        start "$env:ProgramData\apps\7-Zip*.msi" /qn -Wait

        start "$env:ProgramData\apps\Notepad++*.exe" /S -Wait

        start "$env:ProgramData\apps\RustDesk*.exe" --silent-install #-wait

        start "$env:ProgramData\apps\*Chrome*.exe" "--do-not-launch-chrome --system-level" -Wait

    } else {
        echo 'There are no essential apps to install'
    }

    # Cleanup
    if (!(Test-Path "$env:PROGRAMFILES\Internet Explorer\iexplore.exe")) {
        rm -fo "$env:SystemDrive\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Internet Explorer.lnk"
    }

    if (Test-Path "$env:ProgramData\apps") {
        rm -r -fo "$env:ProgramData\apps"
        rm -r -fo "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\RustDesk Tray.lnk"
    } else {
        echo 'No cleanup needed'
    }
}

else {
    Write-Host -b black -f yellow "This script is designed to run in audit mode only."
    echo 'Press enter to exit'
    $null = $Host.UI.ReadLine()
}
