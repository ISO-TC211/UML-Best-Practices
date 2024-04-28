option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: VC Massive Update
' Author: Knut Jetlund
' Purpose: Massive update from Version Control, with export of HTML View and XMI files
' Date: 2016-09-30
'
const cMainFolder = "C:\DATA\GitHub\hmmg-html\"

Sub copyTheFile(strFile, strCopy)
'Copy repository file
   Dim fso, msg
   Set fso = CreateObject("Scripting.FileSystemObject")
   If (fso.FileExists(strFile)) Then
	  msg = "Copying file " & strFile & " to " & strCopy
	  fso.CopyFile strfile, strCopy
   Else
      msg = strFile & " doesn't exist."
   End If
   Session.Output(Now & " " & msg)
End Sub

Function BrowseForFolder(strDefault)
'Browse for a folder
	Dim shell : Set shell = CreateObject("Shell.Application")
	Dim folder : Set folder = shell.BrowseForFolder(0, "Choose a folder:", 0)
	
	if (not folder is nothing) then
		BrowseForFolder = folder.self.Path
	else
		BrowseForFolder = strDefault
	end if
End Function

sub main
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 

	dim eaMod as EA.Package
	dim eaPackage as EA.Package	
	dim pI as EA.Project
	set pI = Repository.GetProjectInterface()

	Dim strThisRep
	strThisRep = Repository.ConnectionString
	Session.Output(Now & " Project: " & strThisRep)
	
	dim fso, msg
	Set fso = CreateObject("Scripting.FileSystemObject")

	'############ EXPORT TO HTML ################
	Session.Output(Now)
	Session.Output(Now & " Exporting to HTML")
	'Export to HTML

	for each eaMod in Repository.Models
		dim strHTMLmodFolder
		strHTMLmodFolder = cMainfolder & Replace(eaMod.Name," ","") & "\"
		Session.Output(Now & " Model: " & eaMod.Name & ", HTML Folder :" & strHTMLmodFolder)
		
		'Create folder if needed
		If (fso.FolderExists(strHTMLmodFolder)) Then
			msg = "Existing folder " & strHTMLmodFolder
		Else
			msg = "Creating folder " & strHTMLmodFolder
			fso.CreateFolder(strHTMLmodFolder)
		End If
		Session.Output(Now & " " & msg)
		
		pI.RunHTMLReport eaMod.PackageGUID, strHTMLmodFolder,"png","<default>",".htm"
	next	
	Session.Output(Now & " Finished. Closing and restarting project.")

end sub

main