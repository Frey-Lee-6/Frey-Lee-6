Option Explicit

Dim shell, fso, appDir, ps1, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

appDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = fso.BuildPath(appDir, "FxWidget.ps1")

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command " & _
  Chr(34) & "$scriptPath = '" & Replace(ps1, "'", "''") & "'; " & _
  "$code = Get-Content -Raw -Encoding UTF8 $scriptPath; " & _
  "Invoke-Expression $code" & Chr(34)

shell.Run command, 0, False
