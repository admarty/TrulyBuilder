# Author: github.com/admarty
# Licensed under the GPL-3.0 License

# This PowerShell script automatically checks the status of Real-Time Protection, toggling it from on to off if currently on, and vice versa.
# Additionally, it presents a small notification window to indicate the change.


# Check if the script is running with administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# PauseThenExit if not running as administrator
if (-not $isAdmin) {
    echo ''
    Write-Warning 'Administrator privileges required. Please run the script with administrator.'
    Pause
    exit
}

# Function to create and show the notification window
Add-Type -AssemblyName System.Windows.Forms
function Show-NotificationWindow ($status) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Windows Defender"
    $form.Size = New-Object System.Drawing.Size (285,80)
    $form.StartPosition = "CenterScreen"
    $form.Topmost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "$status Real-time Protection"
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point (20,7)

    # Increase font size
    $font = New-Object System.Drawing.Font ("Arial",13)
    $label.Font = $font

    $form.Controls.Add($label)

    # Timer to close the form after 2,5 seconds (2500 milliseconds)
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 2500
    $timer.Add_Tick({
            $form.Close()
            $timer.Stop()
            $timer.Dispose()
        })

    $form.Add_Shown({ $timer.Start() })

    $form.ShowDialog()
}

# Check if DisableRealtimeMonitoring is true or false
$disableRealtimeMonitoring = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring

# If DisableRealtimeMonitoring is true
if ($disableRealtimeMonitoring) {
    # Remove the DisableRealtimeMonitoring registry key
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -Force | Out-Null
    # Start the Windows Defender service if it is not currently running.
    Start-Service -Name windefend | Out-Null
    # Enable Real-time monitoring
    Set-MpPreference -DisableRealtimeMonitoring $false
    Show-NotificationWindow "Enabled"

}
# If DisableRealtimeMonitoring is false
else {
    # Create the registry key if it does not exist
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
    # Set the DisableRealtimeMonitoring registry key to 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -Value 1 | Out-Null
    # Disable Real-time monitoring
    Set-MpPreference -DisableRealtimeMonitoring $true
    Show-NotificationWindow "Disabled"
}
