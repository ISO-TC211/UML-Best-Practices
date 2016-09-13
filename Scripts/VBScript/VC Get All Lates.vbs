option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: VC Get all lates
' Author: Knut Jetlund
' Purpose: Get all latest for a selected package and subpackages, and not all other packages in the project
' Date: 20160902
'

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

sub getAllLatest
	' Show and clear the script output window
	Repository.ClearOutput "Script"
	Repository.EnsureOutputVisible "Script"
	'Repository.CreateOutputTab "Error"
	'Repository.ClearOutput "Error"
	Repository.ClearOutput "Version Control"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing then
		recGetAllLatest(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Version Control tab", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

getAllLatest