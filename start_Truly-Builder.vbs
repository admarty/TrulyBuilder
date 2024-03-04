Set objShell = CreateObject("Shell.Application")

scriptDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
srcFolder = scriptDir & "src\"

' Run Truly_Builder script as admin
scriptPath = srcFolder & "Truly-Builder.ps1"
objShell.ShellExecute "conhost", "powershell -ExecutionPolicy Bypass -File """ & scriptPath & """", "", "runas", 1
