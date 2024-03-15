# Audit Script: Automated Windows Audit Mode
# Author: github.com/admarty


# Check the value of AuditBoot
$auditBoot = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status" -Name "AuditBoot"). "AuditBoot"

# Execute only when in audit mode
if ($auditBoot -ne 0) {
    $ErrorActionPreference = "SilentlyContinue"
	$isWin10 = (Get-WmiObject Win32_OperatingSystem).Caption -match "Windows 10"

    # Update UnattendFile
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v "UnattendFile" /t REG_SZ /d "C:\ProgramData\oobe_mode.xml" /f

    # Disable hibernate
    powercfg /h off

    # Allow incoming IPv4 Ping
    netsh advfirewall firewall add rule name="Allow incoming IPv4 echo requests" protocol=icmpv4:8,any dir=in action=allow

    # Allow incoming IPv6 Ping
    netsh advfirewall firewall add rule name="Allow incoming IPv6 echo requests" protocol=icmpv6:128,any dir=in action=allow


    # Silently install essential apps
    if (Test-Path "$env:ProgramData\apps") {

        # Windows Terminal for Win10
        if ($isWin10) {
            $Terminal = dir "$env:ProgramData\apps\*Terminal*.msix" | Select-Object -Exp FullName
            $UI_Xaml_8 = dir "$env:ProgramData\apps\Dependencies\*UI.Xaml_8*.msix" | Select-Object -Exp FullName
            Add-AppxProvisionedPackage -Online -SkipLic -Reg all -PackagePath $Terminal -Depend $UI_Xaml_8 | Out-Null
        }

        start "$env:ProgramData\apps\7-Zip*.msi" /qn -Wait

        start "$env:ProgramData\apps\Notepad++*.exe" /S -Wait

        start "$env:ProgramData\apps\RustDesk*.exe" --silent-install #-wait

        start "$env:ProgramData\apps\*Chrome*.exe" "--do-not-launch-chrome --system-level" -Wait

    }

    # Cleanup
    if (!(Test-Path "$env:PROGRAMFILES\Internet Explorer\iexplore.exe")) {
        rm -fo "$env:SystemDrive\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Internet Explorer.lnk"
        rm -fo "$env:WINDIR\OEM\ie.vbs"
    }

    if (Test-Path "$env:ProgramData\apps") {
        rm -r -fo "$env:ProgramData\apps"
        rm -r -fo "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\RustDesk Tray.lnk"
    }

    if (!$isWin10) {
        rm -fo "$env:WINDIR\OEM\terminal_icon.ico"
    }
}

else {
    Write-Host -b black -f yellow "This script is designed to run in audit mode only."
    echo 'Press any key to exit'
    $null = $host.UI.RawUI.ReadKey()
}
