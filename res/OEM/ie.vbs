' Author: admarty@github.com

' Helper script to combat the "Internet Explorer 11 is no longer supported"

Dim ie

' Attempt to create Internet Explorer object
Set ie = Nothing
On Error Resume Next
Do While ie Is Nothing
    Set ie = CreateObject("InternetExplorer.Application")
    If Err.Number <> 0 Then
        MsgBox "Please wait for 25 seconds.", vbExclamation, "Error"
        Err.Clear
        WScript.Sleep 25000 ' Wait for 25 seconds
    End If
Loop
On Error GoTo 0

' Navigate to google search
ie.Navigate "https://www.google.com/"

' Set the properties for the Internet Explorer window
ie.Visible = 1
ie.Top = 10
ie.Left = 180
ie.Width = 1024
ie.Height = 720

' Clean up
Set ie = Nothing
