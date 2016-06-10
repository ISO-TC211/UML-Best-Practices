option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Resync status with VC provider
' Author: Knut Jetlund
' Purpose: Clean up version control - loops trough a selected package and subpackages, and resyncs status with VC Proovider. 
' Date: 20150424
'

sub recResyncStatus(p)
	if p.IsVersionControlled then
		Repository.WriteOutput "Script", Now & " Version controlled package: " & p.Name, 0
		p.VersionControlResynchPkgStatus False
		Repository.EnsureOutputVisible "Script"
	else
		Repository.WriteOutput "Script", Now & " Uncontrolled package: " & p.Name, 0
	end if	
	
	dim subP as EA.Package
	for each subP in p.packages
	    recResyncStatus(subP)
	next
end sub

sub resyncStatus
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
		recResyncStatus(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Version Control tab", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

resyncStatus