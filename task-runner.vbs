Set wShell = CreateObject ("Wscript.Shell")
strPath = Wscript.ScriptFullName
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.GetFile(strPath)
strFolder = objFSO.GetParentFolderName(objFile)


If Wscript.Arguments.Count = 0 Then
    runPath = strFolder & "\run.js"
Else
    Set oAL = CreateObject("System.Collections.ArrayList")
    For Each oItem In Wscript.Arguments: oAL.Add oItem: Next
    args = Join(oAL.ToArray, " ")
    runPath = strFolder & "\run.js " & args
End If

wShell.Run "node " & runPath, 0
