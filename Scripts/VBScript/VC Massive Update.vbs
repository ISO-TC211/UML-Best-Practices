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

sub recGetAllLatest(p)
'Get all latest for a package and subpackages
	dim localP as EA.Package
	set localP = p
	
	if localP.IsVersionControlled then
		dim pGUID
		pGUID = localP.PackageGUID
		Session.Output(Now & " Version controlled package: " & localP.Name & " (" & localP.PackageGUID &")")
		localP.VersionControlGetLatest false
		'Get new version of the package, after GetLatest. to be sure new subpackages are included
		set localP = Repository.GetPackageByGuid(pGUID)
		localP.Packages.Refresh
		Repository.EnsureOutputVisible "Script"
	else
		Session.Output(Now & " Uncontrolled package: " & localP.Name)
	end if	
	
	dim subP as EA.Package
	for each subP in localP.Packages
	    recGetAllLatest(subP)
	next
end sub

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

sub recExport(p, XmiExportType, path, pI)
'Export to XMI
	if p.IsVersionControlled then
		dim result
		dim fName 
		fName = Replace(p.Name,":","_")
		fName = Replace(fName,"/","")
		Session.Output(Now & " Exporting package: " & p.Name & " Filename: " &  path & fName & ".xmi")
		result = pI.ExportPackageXMI(p.PackageGUID, XmiExportType, 1, -1, 1, 0, path & fName & ".xmi")
		Repository.EnsureOutputVisible "Script"
	else
		Session.Output(Now & " Uncontrolled package: " & p.Name)
	end if	
	
	dim subP as EA.Package
	for each subP in p.packages
	    recExport subP,XmiExportType, path, pI
	next
end sub


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
	
	'########### GET LATEST FROM VC ################
	Session.Output(Now)	
	Session.Output(Now & " Updating packages from Version Control")
	'Find version controlled packages and get latest
	for each eaMod in Repository.Models
		Session.Output(Now & " Model: " & eaMod.Name)
		for each eaPackage in eaMod.Packages
			Session.Output(Now & " Package: " & eaPackage.Name)
			recGetAllLatest(eaPackage)
		next
	next

	'############ EXPORT TO XMI ################
	'Get main folder, for use in export routines
	Session.Output(Now)
	Session.Output(Now & " Exporting to XMI")
	dim pos
	pos=InStrRev(strThisRep,"\")
	pos=InStrRev(Left(strThisRep,pos-1),"\")
	
	'Find main folder (one level down from project folder)
	dim strMainFolder
	if pos = 0 then
		strMainFolder=BrowseForFolder(cMainFolder)
	else	
		strMainFolder=Left(strThisRep,pos) 
	end if	
	
	'Export to XMI
	dim strXMIfolder
	strXMIfolder=strMainfolder & "XMI\2.1\"
	dim XmiExportType
	XmiExportType = 12 'UML 2.1.1 (XMI 2.1) 
	for each eaMod in Repository.Models
		dim strXMImodFolder
		strXMImodFolder = strXMIfolder & Replace(eaMod.Name," ","") & "\"
		Session.Output(Now & " Model: " & eaMod.Name & " XMI Folder " & strXMImodFolder)
		
		'Create folder if needed
		dim fso, msg
		Set fso = CreateObject("Scripting.FileSystemObject")
		If (fso.FolderExists(strXMImodFolder)) Then
			msg = "Existing folder " & strXMImodFolder
		Else
			msg = "Creating folder " & strXMImodFolder
			fso.CreateFolder(strXMImodFolder)
		End If
		Session.Output(Now & " " & msg)
		
		for each eaPackage in eaMod.Packages
			Session.Output(Now & " Package: " & eaPackage.Name)
			recExport eaPackage,XmiExportType,strXMImodFolder,pI
		next
	next
	
	'############ EXPORT TO HTML ################
	Session.Output(Now)
	Session.Output(Now & " Exporting to HTML")
	'Export to HTML
	dim strHTMLfolder
	strHTMLfolder=strMainfolder & "HTML\"
	for each eaMod in Repository.Models
		dim strHTMLmodFolder
		strHTMLmodFolder = strHTMLfolder & Replace(eaMod.Name," ","") & "\"
		Session.Output(Now & " Model: " & eaMod.Name & " HTML Folder " & strHTMLmodFolder)
		
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
	
	'Create copy without SVN
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