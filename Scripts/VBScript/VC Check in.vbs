option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: VC Check in
' Author: Knut Jetlund
' Purpose: Check in selected package and subpackages, and not all other packages in the project
' Date: 20160623
'
const strComment = "Fjerna SOSI Fellesegenskaper, som var lagt inn ved en feil"

sub recCheckIn(p)
	if p.IsVersionControlled then
		Repository.WriteOutput "Script", Now & " Version controlled package: " & p.Name & " (Status " & p.VersionControlGetStatus & ")", 0
		if p.VersionControlGetStatus = 2 then
			p.VersionControlCheckinEx  strComment,false
			p.packages.refresh
		end if	
		Repository.EnsureOutputVisible "Script"
	else
		Repository.WriteOutput "Script", Now & " Uncontrolled package: " & p.Name, 0
	end if	
	
	dim subP as EA.Package
	for each subP in p.packages
	    recCheckIn(subP)
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
		recCheckIn(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Version Control tab", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main