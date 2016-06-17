option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: RemoveVersionControl
' Author: Knut Jetlund
' Purpose: Remove version control - loops trough a selected package and subpackages, and removes version control
' Date: 20160606
'

sub recRemoveVC(p)
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

sub main
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
		recRemoveVC(thePackage)
		Repository.WriteOutput "Script", Now & " Finished", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main