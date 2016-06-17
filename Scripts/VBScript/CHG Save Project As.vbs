option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: CHG Save Project As
' Author: Knut Jetlund
' Purpose: Save project with a new name
' Date: 20160616
'

const path = "C:\DATA\GitHub\HMMG\EA\"
const strWithSVN = "ISOTC211_HM.eap"
const strNoSVN = "ISOTC211_HM_NoSVN.eap"

Sub CopyTheFile()
   Dim fso, msg
   Set fso = CreateObject("Scripting.FileSystemObject")
   If (fso.FileExists(path & strWithSVN)) Then
	  msg = "Copying file " & path & strWithSVN
	  fso.CopyFile path & strWithSVN, path & strNoSVN
   Else
      msg = path & strWithSVN & " doesn't exist."
   End If
   Session.Output(Now & " " & msg)
End Sub

sub main
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 
	'Copy existing EA file
	CopyTheFile()
	'Save as new EA file
	Session.Output(Now & " Repository: " & Repository.ConnectionString)
	Repository.OpenFile(path & strNoSVN)
end sub

main