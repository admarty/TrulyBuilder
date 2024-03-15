# Check the value of AuditBoot
$auditBoot = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status" -Name "AuditBoot")."AuditBoot"

# Execute only when in audit mode
if ($auditBoot -ne 0) {
    $ErrorActionPreference = "SilentlyContinue"

    echo ''
    $scanHealth = Read-Host "Run ScanHealth? If the image is corrupt, auto-run RestoreHealth (y/N)"
    echo ''
    if ($scanHealth -eq 'y') {
        $result = Repair-WindowsImage -Online -ScanHealth
        if ($result.ImageHealthState -ne "Healthy") {
            Write-Host 'The component store is corrupted. Try repairing...'
            Repair-WindowsImage -Online -RestoreHealth | out-null
        } else {
            Write-Host 'No component store corruption detected.'
            sleep 5
        }
    }

    cls

    $sysprepProcess = ps sysprep
    if ($sysprepProcess -ne $null) {
        kill $sysprepProcess.Id -fo
    }

    do {
        $invalidChoice = $false
        Write-Host "Choose an option:"
        echo ''
        Write-Host "1: Restarts the computer into OOBE"
        echo ''
        Write-Host "2: Shut down the computer; the next boot is OOBE."
        echo ''
        Write-Host "3: Generalizes the image and shuts down. Prepares to be imaged. (Capture-Image with Dism)"
        echo ''
        Write-Host "4: Open Sysprep GUI"
        echo ''

        $choice = Read-Host "Enter the option number (1-4)"
        echo ''

        switch ($choice) {
            1 {
                $sysprepArgs = '/reboot /oobe'
            }
            2 {
                $sysprepArgs = '/shutdown /oobe'
            }
            3 {
                $sysprepArgs = '/shutdown /oobe /generalize'
            }
            4 {
                $sysprepArgs = ''
            }
            default {
                Write-Host "Invalid choice. Please choose again."
                $invalidChoice = $true
            }
        }
    } while ($invalidChoice)

    $sysprepPath = "$env:WINDIR\system32\sysprep\sysprep.exe"

    Remove-AppxPackage NotepadPlusPlus_1.0.0.0_neutral__7njy0v32s6xk6 2>&1 | out-null

    if ($sysprepArgs -eq '') {
        start $sysprepPath
    } else {
        Write-Host "Starting sysprep with the following args:"
        echo ''
        Write-Host "$sysprepPath $sysprepArgs"
        sleep 4
        start $sysprepPath $sysprepArgs
    }

} else {
    Write-Host -b black -f yellow "This script is designed to run in audit mode only."
    echo 'Press any key to exit'
    $null = $host.UI.RawUI.ReadKey()
}
