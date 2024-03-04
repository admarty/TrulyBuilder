' Author: admarty@github.com

' This script dynamically checks Windows Defender's Tamper Protection status and guides users accordingly.
' If Tamper Protection is active, it prompts users to manually disable it and conveniently opens the Defender Threat settings window.
' If Tamper Protection is not enabled, the script seamlessly runs RealtimeProtectionSwitch.ps1 with elevated privileges.

Set objShell = CreateObject("WScript.Shell")

' Get the script's directory
scriptDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

' Registry path to check TamperProtection
registryPath = "HKLM\SOFTWARE\Microsoft\Windows Defender\Features"

' Get the TamperProtection value from the registry
tamperProtectionValue = objShell.RegRead(registryPath & "\TamperProtection")

'  If TamperProtection value is 5 or 1
If tamperProtectionValue = 5 Or tamperProtectionValue = 1 Then
    ' Display a message box asking the user to manually disable Tamper Protection
    MsgBox "Manually disable Tamper Protection in Windows Defender settings to utilize this function", vbInformation

    ' Open Threatsettings
    objShell.Run "explorer windowsdefender://Threatsettings"

Else
    ' Run RealtimeProtectionSwitch script as admin
    Set objShell = CreateObject("Shell.Application")
    scriptPath = scriptDir & "RealtimeProtectionSwitch.ps1"
    objShell.ShellExecute "powershell", "-exec bypass -window hidden -file """ & scriptPath & """", "", "runas", 1
End If
