option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: VC Massive Update
' Author: Knut Jetlund
' Purpose: Massive update from Version Control, with export of HTML View and XMI files
' Date: 2016-09-30
'
const cMainFolder = "C:\DATA\GitHub\HMMG"

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

sub recRemoveVC(p)
'Remove version control
	if p.IsVersionControlled then
		Repository.WriteOutput "Script", Now & " Removing Version Controll from package: " & p.Name, 0
		p.VersionControlRemove 
		Repository.EnsureOutputVisible "Script"
	else
		Repository.WriteOutput "Script", Now & " Uncontrolled package: " & p.Name, 0
	end if	
	
	dim subP as EA.Package
	for each subP in p.packages
	    recRemoveVC(subP)
	next
end sub

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
	
	'############ CREATE COPY WITHOUT VC ################
	Session.Output(Now)
	Session.Output(Now & " Removing Version Control")

	'Create backup project
	dim strBackup, strLength	
	strLength = Len(strThisRep)
	strBackup = Left(strThisRep,strLength-4) & "_Backup.eap"
	CopyTheFile strThisRep,strBackup
	
	'Remove version control
	for each eaMod in Repository.Models
		Session.Output(Now & " Model: " & eaMod.Name)
		for each eaPackage in eaMod.Packages
			Session.Output(Now & " Package: " & eaPackage.Name)
			recRemoveVC(eaPackage)
		next
	next
	
	'Create copy without SVN and without scripts
	Dim strNoSVN
	strNoSVN = Left(strThisRep,strLength-4) & "_NoSVN.eap"
	Session.Output(Now & " Saving project without SVN: " & strNoSVN)
	CopyTheFile strThisRep,strNoSVN
	
    'Restore from backup
	strBackup = Left(strThisRep,strLength-4) & "_Backup.eap"
	Session.Output(Now & " Restoring from backup")
	CopyTheFile strBackup, strThisRep
	
	Session.Output(Now & " Finished. Closing and restarting project.")
	Repository.CloseFile
	Repository.OpenFile strThisRep
	Repository.EnsureOutputVisible "Script"	

end sub

main