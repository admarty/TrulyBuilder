# Truly-Builder: A template to truly build customized Windows images.
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.


# Define paths and variables (modify as needed)
$default_isoName = '0.1_Truly' # The prefix '.iso' is already included
$isoLabel = 'DVD_ROM'
$tempDir = "${env:SystemDrive}\Truly-Builder_temp"
$mntDir = "${env:SystemDrive}\Truly-Builder_mount"

# Predefined list of Appx Packages to remove (modify as needed)
$predefinedAppxPackages = @(
    'Clipchamp',
    '549981', # Cortana
    'BingNews',
    'BingWeather',
    'GamingApp', # Win11 Xbox
    'GetHelp',
    'Getstarted',
    '3DViewer',
    'OfficeHub',
    'OneNote',
    'Solitaire',
    'MixedReality',
    'MSPaint', # Win10 Paint3D
    'Outlook',
    #'Paint', # Win11 Paint
    'People',
    'SkypeApp',
    'PowerAutomateDesktop',
    'Todos',
    'DevHome',
    #'Photos',
    #'Alarms', # Clock
    'windowscommunications', # Mail
    'FeedbackHub',
    'Maps',
    #'Notepad',
    'SoundRecorder',
    'XboxApp', # Win10 Xbox
    #'Terminal',
    'Xbox.TCUI',
    'XboxGameOverlay',
    'XboxGamingOverlay',
    'XboxSpeech',
    'YourPhone',
    #'ZuneMusic', # Media Player
    'ZuneVideo', # Movies & TV
    'MicrosoftFamily',
    'QuickAssist',
    'Client.WebExperience', # Win11 Widgets
    'Teams'
)

# Predefined list of Windows capabilities to remove (modify as needed)
$predefinedCapabilities = @(
    'StepsRecorder',
    'QuickAssist',
    'Hello.Face',
    'InternetExplorer',
    #'Language.Handwriting',
    #'Language.OCR',
    'Language.Speech',
    'Language.TextToSpeech',
    'MathRecognizer',
    'MediaPlayer', # Legacy Windows Media Player
    #'Windows.MSPaint',
    #'Wallpapers.Extended',
    #'Ethernet', # Ethernet driver
    #'Notepad',
    #'Wifi', # Wifi driver
    'OneCoreUAP.OneSync', # Sync component for Mail, People, and Calendar
    #'OpenSSH.Client',
    'Kernel.LA57', # Use by Ryzen Threadripper PRO 7900WX series, EPYC 9004 Series and Ice Lake microarchitecture
    'WordPad'
)

# Predefined list of Windows optional feature to disable (modify as needed)
$predefinedOptionalFeatures = @(
    #'Windows-Defender-Default-Definitions',
    'Printing-PrintToPDFServices-Features',
    'Printing-XPSServices-Features',
    #'MSRDC-Infrastructure',
    #'Microsoft-SnippingTool',
    #'WCF-Services45',
    #'MediaPlayback',
    #'SearchEngine-Client-Package',
    #'Microsoft-RemoteDesktopConnection',
    'WorkFolders-Client',
    #'Printing-Foundation-Features'
    #'MicrosoftWindowsPowerShellV2',
    #'NetFx3', # .NET Framework 3
    #'NetFx4-AdvSrvs', # .NET Framework 4
    'Internet-Explorer-Optional-amd64',
    'SmbDirect'
)

# Hostnames to be added to the hosts file (modify as needed)
$hostnames = @(
    '# Diagnostic Data'
    '0.0.0.0 functional.events.data.microsoft.com',
    '0.0.0.0 browser.events.data.msn.com',
    '0.0.0.0 self.events.data.microsoft.com',
    '0.0.0.0 v10.events.data.microsoft.com'
)

# Define a list of Winget app IDs to be installed with the audit_script. Modify as needed, and don't forget to update the audit_script accordingly.
$essentialApps = @(
    'Google.Chrome',
    'Notepad++.Notepad++',
    '7zip.7zip',
    'RustDesk.RustDesk',
    'Microsoft.WindowsTerminal'
)

# Define file paths and their destinations for copying into the image (modify as needed)
function Initialize-FilePathsForCopy {
    $global:filePaths = @{
        "$scriptRoot\res\OEM" = "${mntDir}\Windows\"
        "$scriptRoot\src\audit_script.ps1" = "${mntDir}\ProgramData\"
        "$scriptRoot\src\Sysprep.ps1" = "${mntDir}\Users\Public\Desktop\"
        "$scriptRoot\res\oobe_mode_unattend.xml" = "${mntDir}\ProgramData\oobe_mode.xml"
        "$scriptRoot\res\audit_mode_unattend.xml" = "${mntDir}\ProgramData\audit_mode.xml"
        "$scriptRoot\res\${winver}_StartMenuLayouts.xml" = "$mntDir\Users\Default\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml"
        "$scriptRoot\res\Internet Explorer.lnk" = "${mntDir}\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\"
    }
}


# This is the main function of the script
function Main {

    FindMountedWindowsISO

    SelectImageToProceed

    SetISOPathAndName

    SelectRemovalMethod

    PauseBeforeIsoCreation

    IncludeEssentialApps

    CleanupDirs

    PromptOnErrors

    Write-Host ''
    Write-Host "Copying installation files from the mounted ISO to ${tempDir}..."
    mkdir -fo $tempDir | Out-Null
    copy -r -fo "${drive}:\*" $tempDir | Out-Null
    Write-Host ''

    HandleWinImageConversion

    Write-Host "Mounting the selected image: ${imageName}..."
    Write-Host ''
    Set-ItemProperty "$tempDir\sources\install.wim" IsReadOnly $false
    mkdir -fo $mntDir | Out-Null
    Mount-WindowsImage -Path $mntDir -ImagePath "$tempDir\sources\install.wim" -Name "$imageName" | Out-Null

    PromptOnErrors

    Write-Host -b black -f green 'Start removing Appx Packages...'
    Write-Host ''
    RemoveAppxPackages

    Write-Host ''

    Write-Host -b black -f green 'Start removing Windows capabilities...'
    Write-Host ''
    RemoveCapabilities

    Write-Host ''

    Write-Host -b black -f green 'Start disabling Optional Features...'
    Write-Host ''
    DisableOptionalFeatures

    Write-Host ''
    ModifyRegistry

    PromptOnErrors

    ModifyHostsFile

    Write-Host -b black -f green 'Import Default App Associations...'
    $AppAssociations = "$scriptRoot\res\${winver}_AppAssociations.xml"
    dism /image:$mntDir /Import-DefaultAppAssociations:$AppAssociations | Out-Null
    Write-Host ''

    Write-Host -b black -f green 'Transferring custom files to the image...'
    Write-Host ''
    CopyFilesIntoImage

    Write-Host ''

    attrib +h "${mntDir}\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" | Out-Null

    PromptOnErrors

    CheckPause

    Write-Host 'Unmounting and saving changes to the image...'
    Write-Host ''
    Dismount-WindowsImage -Path $mntDir -Save -CheckIntegrity | Out-Null
    CriticalErrorAbort

    Write-Host 'Exporting Windows image...'
    Write-Host ''
    Export-WindowsImage -SourceImage "$tempDir\sources\install.wim" -DestinationImage "$tempDir\sources\install.wim.new" -SourceName "$imageName" -Compression 'max' -CheckIntegrity | Out-Null
    CriticalErrorAbort
    rm -r -fo "$tempDir\sources\install.wim"
    Rename-Item -fo "$tempDir\sources\install.wim.new" "$tempDir\sources\install.wim"

    Write-Host -b black -f green 'Windows Image successfully exported, proceeding to create an ISO file...'
    Write-Host ''
    copy "$scriptRoot\res\autounattend.xml" "$tempDir\autounattend.xml"

    CreateBootableIso
    Write-Host ''

    CleanupDirs

    PauseThenExit
}


# Function to finds the mounted Windows ISO
function FindMountedWindowsISO {
    do {
        Write-Host ''
        # Get all available drive letters in the system
        $drives = Get-Volume | Select-Object -ExpandProperty DriveLetter

        foreach ($driveLetter in $drives) {
            if (Test-Path "${driveLetter}:\sources\install.wim") {
                $confirmation = Read-Host "Detected Windows ISO mounted on drive '${driveLetter}:\'. Would you like to use it? (Y/n)"
                Write-Host ''

                if ($confirmation -ne 'n') {
                    $global:drive = $driveLetter
                    $global:imageFormat = 'wim'
                    $found = $true
                    break
                }
            } elseif (Test-Path "${driveLetter}:\sources\install.esd") {
                $confirmation = Read-Host "Detected Windows ISO mounted on drive '${driveLetter}:\'. Would you like to use it? (Y/n)"
                Write-Host ''

                if ($confirmation -ne 'n') {
                    $global:drive = $driveLetter
                    $global:imageFormat = 'esd'
                    $found = $true
                    break
                }
            }
        }

        if (!($found)) {
            Write-Warning 'Please mount the Windows ISO file, and then press Enter to check again.'
            $null = Read-Host
        }
    } while (!($found))
}


# Function to select a Windows image from mounted Windows ISO
function SelectImageToProceed {
    # Get the Windows images
    $windowsImages = Get-WindowsImage -ImagePath "${drive}:\sources\install.${imageFormat}"
    $validImageIndexes = $windowsImages.ImageIndex

    do {
        # Display the available images
        Write-Host "Available Windows Images:"
        Write-Host ''
        foreach ($image in $windowsImages) {
            Write-Host "ImageIndex: $($image.ImageIndex) : $($image.ImageName)"
        }
        Write-Host ''
        $selectedImageIndex = Read-Host "Select an ImageIndex number to proceed"
        Write-Host ''

        if ($validImageIndexes -notcontains $selectedImageIndex) {
            Write-Warning "Invalid ImageIndex. Please choose a valid ImageIndex number."
            $selectedImage = $null
        } else {
            $selectedImage = $windowsImages | Where-Object { $_.ImageIndex -eq $selectedImageIndex }
        }
    } while ($selectedImage -eq $null)

    $global:imageName = $selectedImage.ImageName
    if ($imageName -like 'Windows 10*') {
        $global:winver = 'win10'
        $global:verNum = '10'
    } elseif ($imageName -like 'Windows 11*') {
        $global:winver = 'win11'
        $global:verNum = '11'
    } elseif ($imageName -like 'Windows 12*') {
        $global:winver = 'win12'
        $global:verNum = '12'
        Write-Warning 'This script does not currently support this Windows version.'
        PauseThenExit
    } else {
        $global:winver = 'unknown'
        Write-Warning 'This script does not currently support this Windows version.'
        PauseThenExit
    }
}


# Function to set ISO file path and name
function SetISOPathAndName {
    Write-Host -b black -f cyan "The prefix '.iso' is already included."
    $isoName = Read-Host "Enter file name for the modified ISO (optional, default: ${default_isoName}_${verNum}.iso)"
    Write-Host ""

    if ($isoName -eq '') {
        Write-Host -b black -f cyan "Using default file name: ${default_isoName}_${verNum}.iso"
        $isoName = "$default_isoName"
    } else {
        # Replace special characters in the filename to avoid issues
        $isoName = $isoName -replace '[\\/:*"<>|?\\]',''
    }

    $global:isoPath = "$scriptRoot\${isoName}_${verNum}.iso"

    if (Test-Path $isoPath) {
        $confirmation = Read-Host "File named '${isoName}_${verNum}.iso' already exists. Do you want to overwrite it? (Y/n)"
        if ($confirmation -ne 'n') {
            Dismount-DiskImage $isoPath | Out-Null
        } else {
            PauseThenExit
        }
    }
    Write-Host ''
}


# Function prompts the user to confirm whether essential apps are needed
function IncludeEssentialApps {
    $appsDir = "${scriptRoot}\apps"
    Initialize-FilePathsForCopy

    $includeApps = Read-Host "Do you want to include essential apps like Chrome, Notepad++, 7-Zip, and RustDesk? (Y/n)"
    if ($includeApps -eq 'n') {
        Write-Host -b black -f cyan 'Skipping installation of essential apps.'
        return
    } else {
        $global:filePaths["$appsDir"] = "${mntDir}\ProgramData\"
    }

    if (!(gcm winget)) {
        Write-Host ''
        Write-Host -b black -f yellow "The 'winget' command is unavailable. Update 'App Installer' through Microsoft Store and then run this script again."
        Write-Host ''
        Write-Host -b black -f cyan 'Microsoft Store will open automatically in 5 seconds.'
        sleep 5
        start "ms-windows-store://pdp?hl=en-us&gl=us&productid=9nblggh4nns1"
        PauseThenExit
    }

    if (!(Test-Path $appsDir)) {
        Write-Host 'Creating apps folder...'
        mkdir -fo $appsDir | Out-Null
    } else {
        Write-Host -b black -f cyan 'Apps folder detected. Checking existing apps:'
        dir $appsDir | Select-Object Name,LastWriteTime | Format-Table -AutoSize

        $redownloadApps = Read-Host "Redownload essential apps? (y/N)"
        if ($redownloadApps -ne 'y') {
            return
        }
    }

    rm -r -fo "$appsDir\*"
    Write-Host 'Updating winget source...'
    winget source update --disable-interactivity | Out-Null
    foreach ($app in $essentialApps) {
        if ($app -eq 'Microsoft.WindowsTerminal') {
            if ($winver -ne 'win10') {
                continue
            }
        }

        Write-Host ''
        Write-Host -b black -f cyan "Downloading $app..."
        winget download --id $app -d $appsDir --accept-package-agreements --accept-source-agreements --disable-interactivity --scope machine
    }

    Write-Host -b black -f cyan 'Essential apps download completed.'
}


# Function prompts user to confirm if they want to pause before the creation of the ISO image
function PauseBeforeIsoCreation {
    Write-Host -b black -f cyan 'Pausing the script allows you to make additional modifications to the Windows image or insert custom files into the root directory of the ISO file before it is created.'
    $input = Read-Host 'Would you like to pause before creating the ISO file? (y/N)'
    Write-Host ''

    if ($input -eq 'y') {
        $global:pause = $true
    } else {
        $global:pause = $false
    }
}

# Function to handle PauseBeforeIsoCreation
function CheckPause {
    if ($pause) {
        $driverFolder = Join-Path "$tempDir" '$WinPEDriver$'
        mkdir -fo $driverFolder | Out-Null
        Write-Host -b black -f green "The script is paused. Now you can make additional modifications. Windows image root at: '$mntDir' | ISO root at: '$tempDir'"
        Write-Host -b black -f green "Press any key to continue when you are ready."
        $null = $host.UI.RawUI.ReadKey()
        Write-Host ''
    }
}


# Function to convert install.esd to install.wim when necessary
function HandleWinImageConversion {
    if ($imageFormat -eq 'esd') {
        Write-Host -b black -f cyan "Converting install.esd to install.wim..."
        Write-Host ''
        Export-WindowsImage -SourceImage "$tempDir\sources\install.esd" -DestinationImage "$tempDir\sources\install.wim" -SourceName "$imageName" -Compression 'max' | Out-Null
        rm -fo "$tempDir\sources\install.esd"
    }
}


# Function to choose the removal method for Appx packages, Windows capabilities, and Optional Features
function SelectRemovalMethod {
    do {
        Write-Host -b black -f cyan "Choose a removal method: Press 1 for the 'predefined list' or 2 for 'manual selection'."
        $global:removalMethod = Read-Host "Please proceed by entering 1 or 2"
        Write-Host ''
    } while ($global:removalMethod -ne "1" -and $global:removalMethod -ne "2")
}


# Function to remove Appx provisioned packages based on user choice
function RemoveAppxPackages {
    # Get installed Appx provisioned packages
    $installedAppxPackages = Get-AppxProvisionedPackage -Path $mntDir | Select-Object -ExpandProperty PackageName

    if ($removalMethod -eq '1') {
        # Remove based on predefined Appx packages
        foreach ($appxPackage in $predefinedAppxPackages) {
            $matchingPackages = $installedAppxPackages -like "*$appxPackage*"
            if ($matchingPackages.Count -gt 0) {
                foreach ($matchingPackage in $matchingPackages) {
                    Remove-AppxProvisionedPackage -PackageName $matchingPackage -Path $mntDir | Out-Null
                    Write-Host -b black -f cyan "Appx package '$matchingPackage' removed successfully."
                }
            } else {
                Write-Host -b black -f yellow "No matching Appx package were found for '$appxPackage'."
            }
        }
    } elseif ($removalMethod -eq '2') {
        # Manual removal
        foreach ($appxPackage in $installedAppxPackages) {
            $remove = Read-Host "Are you sure you want to remove: ${appxPackage}? (y/N)"
            if ($remove -eq 'y') {
                Remove-AppxProvisionedPackage -PackageName $appxPackage -Path $mntDir | Out-Null
                Write-Host -b black -f cyan "Appx package '$appxPackage' removed successfully."
                Write-Host ''
            }
        }
    }
}


# Function to remove Windows capabilities based on user choice
function RemoveCapabilities {
    # Get installed capabilities
    $installedCapabilities = Get-WindowsCapability -Path $mntDir | Where-Object { $_.State -eq 'Installed' } | Select-Object -ExpandProperty Name

    if ($removalMethod -eq '1') {
        # Remove based on predefined capabilities
        foreach ($Capability in $predefinedCapabilities) {
            $matchingCapabilities = $installedCapabilities -like "*$Capability*"
            if ($matchingCapabilities.Count -gt 0) {
                foreach ($matchingCap in $matchingCapabilities) {
                    try {
                        Remove-WindowsCapability -Name $matchingCap -Path $mntDir | Out-Null
                        Write-Host -b black -f cyan "Capability '$matchingCap' removed successfully."
                    } catch {
                        Write-Host -b black -f red "Error removing '$matchingCap': $_"; $Error.Clear()
                    }
                }
            } else {
                Write-Host -b black -f yellow "No matching Capability package were found for '$Capability'."
            }
        }
    } elseif ($removalMethod -eq '2') {
        # Manual removal
        foreach ($Capability in $installedCapabilities) {
            $remove = Read-Host "Are you sure you want to remove: ${Capability}? (y/N)"
            if ($remove -eq 'y') {
                try {
                    Remove-WindowsCapability -Name $Capability -Path $mntDir | Out-Null
                    Write-Host -b black -f cyan "Capability '$Capability' removed successfully."
                } catch {
                    Write-Host -b black -f red "Error removing '$Capability': $_"; $Error.Clear()
                }
            }
        }
    }
}


# Function to disable Windows Optional Features with '-Remove' based on user choice
function DisableOptionalFeatures {
    # Get enabled Optional Features
    $enabledOptionalFeatures = Get-WindowsOptionalFeature -Path $mntDir | Where-Object { $_.State -eq 'Enabled' } | Select-Object -ExpandProperty FeatureName

    if ($removalMethod -eq '1') {
        # Disable based on predefined Optional Features
        foreach ($featureName in $predefinedOptionalFeatures) {
            if ($enabledOptionalFeatures -contains $featureName) {
                Disable-WindowsOptionalFeature -FeatureName $featureName -Path $mntDir -Remove | Out-Null
                Write-Host -b black -f cyan "Optional Feature '$featureName' disabled successfully."
            } else {
                Write-Host -b black -f yellow "Optional Feature '$featureName' is not currently enabled."
            }
        }
    } elseif ($removalMethod -eq '2') {
        # Manual disabling
        foreach ($featureName in $enabledOptionalFeatures) {
            $disable = Read-Host "Are you sure you want to disable: ${featureName}? (y/N)"
            if ($disable -eq 'y') {
                Disable-WindowsOptionalFeature -FeatureName $featureName -Path $mntDir -Remove | Out-Null
                Write-Host -b black -f cyan "Optional Feature '$featureName' disabled successfully."
                Write-Host ''
            }
        }
    }
}


# Self-explanatory function
function ModifyRegistry {
    $regfilePath = "$scriptRoot\res\${winver}_offline_tweak.reg"
    Write-Host -b black -f green 'Performing registry tweaks...'
    reg load HKLM\zNTUSER "${mntDir}\Users\Default\NTUSER.DAT" | Out-Null
    reg load HKLM\zSOFTWARE "${mntDir}\Windows\System32\config\SOFTWARE" | Out-Null
    reg load HKLM\zSYSTEM "${mntDir}\Windows\System32\config\SYSTEM" | Out-Null
    reg import $regfilePath
    reg unload HKLM\zNTUSER | Out-Null
    reg unload HKLM\zSOFTWARE | Out-Null
    reg unload HKLM\zSYSTEM | Out-Null
    Write-Host ''
}


# Self-explanatory function
function ModifyHostsFile {
    $path = "${mntDir}\Windows\System32\drivers\etc\hosts"
    Write-Host -b black -f green "Adding hostnames to hosts file at:  ${path}"
    Write-Host ''
    $hosts = Get-Content $path -Raw
    $hosts += $hostnames -join "`r`n"
    $hosts | Set-Content -Path $path -Encoding utf8
}


# Self-explanatory function
function CopyFilesIntoImage {
    foreach ($filePath in $filePaths.GetEnumerator()) {
        $sourcePath = $filePath.Key
        $destinationPath = $filePath.Value

        if (Test-Path $sourcePath -PathType leaf) {
            copy -fo $sourcePath $destinationPath
            Write-Host -b black -f cyan "File '$sourcePath' copied to '$destinationPath'."
        } elseif (Test-Path $sourcePath -PathType container) {
            copy -r -fo $sourcePath $destinationPath
            Write-Host -b black -f cyan "Directory '$sourcePath' copied to '$destinationPath'."
        } else {
            Write-Host -b black -f yellow "Source path '$sourcePath' does not exist."
        }
    }
}


# Function to Generate a bootable ISO from a directory. This function provides a more controlled and transparent method for creating a bootable ISO.
function CreateBootableIso {
    # Script block to be run in a separate process
    $scriptBlock = {
        # base on MakeISO by AveYo
        param($tempDir,$isoPath,$isoLabel)
        $Source = @"
        using System;
        using System.Runtime.InteropServices;
        using System.Runtime.InteropServices.ComTypes;

        public class IsoCreator {
            [DllImport("shlwapi", CharSet = CharSet.Unicode)]
            internal static extern void SHCreateStreamOnFileEx(string f, uint m, uint d, bool b, IStream r, out IStream s);
            public static int Create(string isoPath, ref object sourceStream, int blockSize, int totalBlocks) {
                IStream source = (IStream)sourceStream, isoStream;
                try {
                    SHCreateStreamOnFileEx(isoPath, 0x1001, 0x80, true, null, out isoStream);
                }
                catch (Exception) {
                    return 1;
                }

                int divider = totalBlocks > 1024 ? 1024 : 1;
                int padding = totalBlocks % divider;
                int blockCount = blockSize * divider;
                int totalBlock = (totalBlocks - padding) / divider;

                if (padding > 0) source.CopyTo(isoStream, padding * blockCount, IntPtr.Zero, IntPtr.Zero);
                while (totalBlock-- > 0) {
                    source.CopyTo(isoStream, blockCount, IntPtr.Zero, IntPtr.Zero);
                }

                isoStream.Commit(0);
                return 0;
            }
        }
"@

        Add-Type $Source
        $BOOT = @()
        $bootable = 0
        $mbr_efi = @(0,0xEF)
        $bootfiles = @('boot\etfsboot.com','efi\microsoft\boot\efisys.bin')

        0,1 | ForEach-Object {
            $bootfile = Join-Path $tempDir $bootfiles[$_]
            if (Test-Path $bootfile -PathType Leaf) {
                $bin = New-Object -ComObject ADODB.Stream
                $bin.Open()
                $bin.Type = 1
                $bin.LoadFromFile($bootfile)

                $opt = New-Object -ComObject IMAPI2FS.BootOptions
                $opt.AssignBootImage($bin.psobject.BaseObject)
                $opt.PlatformId = $mbr_efi[$_]
                $opt.Emulation = 0
                $bootable = 1
                $opt.Manufacturer = 'Microsoft'
                $BOOT += $opt.psobject.BaseObject
            }
        }

        $fsi = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
        $fsi.FileSystemsToCreate = 4
        $fsi.FreeMediaBlocks = 0

        if ($bootable) {
            $fsi.BootImageOptionsArray = $BOOT
        }

        $TREE = $fsi.Root
        $TREE.AddTree($tempDir,$false)
        $fsi.VolumeName = $isoLabel

        $obj = $fsi.CreateResultImage()
        $ret = [IsoCreator]::Create($isoPath,[ref]$obj.ImageStream,$obj.BlockSize,$obj.TotalBlocks)

        [GC]::Collect()
        return $ret
    }

    $job = sajb -Script $scriptBlock -args $tempDir,$isoPath,$isoLabel

    $result = rcjb $job -wait -auto
    sleep 2

    if ($result -eq 0) {
        Write-Host -b black -f cyan "The ISO file has been created at $isoPath"
    } else {
        Write-Warning "Creation of the ISO file has failed. Have you made any modifications to the CreateBootableIso function?"
    }
}


# Self-explanatory function
function PromptOnErrors {
    $errors = $Error.Count
    if ($errors -ne 0) {
        Write-Host ''
        Write-Host -b black -f red "There are ${errors} error(s) that occurred. If the error is not significant, you can choose whether to proceed or not."
        $confirmation = Read-Host "Do you want to continue? (Y/n)"
        Write-Host ''
        if ($confirmation -eq 'n') {
            CleanupDirs
            PauseThenExit
            Write-Host ''
        }
        $Error.Clear()
    }
}


# Self-explanatory function
function CriticalErrorAbort {
    if ($Error.Count -ne 0) {
        $Error | ForEach-Object { Write-Host -b black -f red "  $_" }
        Write-Host ''
        Write-Warning 'Something went wrong. Please try running the script again.'
        CleanupDirs
        PauseThenExit
    }
}


# Self-explanatory function
function CleanupDirs {
    if (Test-Path ${mntDir}\Windows) {
        Write-Host -b black -f yellow 'Dismounting image and discarding changes...'
        Write-Host ''
        Dismount-WindowsImage -Path $mntDir -Discard | Out-Null
    }
    if (Test-Path $tempDir) {
        Write-Host "Cleaning up $tempDir"
        rm -r -fo $tempDir
    }
    if (Test-Path $mntDir) {
        Write-Host "Cleaning up $mntDir"
        rm -r -fo $mntDir
    }
}


# Self-explanatory function
function PauseThenExit {
    # Clear any remaining errors and cleanup variables
    rv -fo -sco global *
    $Error.Clear()

    Write-Host ''
    Write-Host 'Operation completed. Press any key to exit.'
    $null = $host.UI.RawUI.ReadKey()
    exit
}

$Error.Clear()
$ErrorActionPreference = "SilentlyContinue"
$scriptRoot = Split-Path $PSScriptRoot -Parent

clear

# Check if the script is running with administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# PauseThenExit if not running as administrator
if (!($isAdmin)) {
    Write-Host ''
    Write-Warning 'Administrator privileges required. Please run the script with administrator.'
    PauseThenExit
}

# Execute the main function of the script
Main
