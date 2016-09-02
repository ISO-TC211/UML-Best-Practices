option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: VC Massive Update
' Author: Knut Jetlund
' Purpose: Massive update from Version Control, with export of HTML View and XMI files
' Date: 2016-09-30
'

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

sub main
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 
	
	Dim strThisRep
	strThisRep = Repository.ConnectionString
	Session.Output(Now & " Project: " & strThisRep)
	
	'Create backup project
	dim strBackup, strLength	
	strLength = Len(strThisRep)
	strBackup = Left(strThisRep,strLength-4) & "_Backup.eap"
	copyTheFile strThisRep,strBackup
	
	'Find version controlled packages and get latest
	dim eaMod as EA.Package
	dim eaPackage as EA.Package
	for each eaMod in Repository.Models
		Session.Output(Now & " Model: " & eaMod.Name)
		for each eaPackage in eaMod.Packages
			Session.Output(Now & " Package: " & eaPackage.Name)
			recGetAllLatest(eaPackage)
		next
	next
	
	'remove version control


	'Create copy without SVN
	Dim strNoSVN
	'strNoSVN = Left(strThisRep,strLength-4) & "_NoSVN.eap"
	'Session.Output(Now & " Project without SVN: " & strNoSVN)
	'CopyTheFile strThisRep,strNoSVN
	
		
	Session.Output(Now & " Finished")
	Repository.EnsureOutputVisible "Script"	

end sub

main