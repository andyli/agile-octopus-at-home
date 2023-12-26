Set wShell = CreateObject ("Wscript.Shell")
strPath = Wscript.ScriptFullName
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.GetFile(strPath)
strFolder = objFSO.GetParentFolderName(objFile)

Select Case Wscript.Arguments.Count
    Case 0
        runPath = strFolder & "\run.js"
    Case 1
        runPath = strFolder & "\run.js " & Wscript.Arguments(0)
    Case 2
        runPath = strFolder & "\run.js " & Wscript.Arguments(0) & " " & Wscript.Arguments(1)    
    Case Else
        Set oAL = CreateObject("System.Collections.ArrayList")
        For Each oItem In Wscript.Arguments: oAL.Add oItem: Next
        args = Join(oAL.ToArray, " ")
        runPath = strFolder & "\run.js " & args
End Select

wShell.Run "node " & runPath, 0
