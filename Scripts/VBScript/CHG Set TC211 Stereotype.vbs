option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: Add package tags 
' Author: Knut Jetlund
' Purpose: Add tags for identifying packages in the ISO/TC211 HM
' Date: 20170803
'
' NOTE: Requires a package to be selected in the Project Browser
' 

'Recursive loop through subpackages, and do the thing
sub recPros(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim pEl as EA.Element
	set pEl = p.Element
	
	Repository.WriteOutput "Script", Now & " Existing stereotype: " & pEl.StereoTypeEx, 0 
	If instr(pEl.StereoTypeEx,"Leaf") then
		pEl.StereoTypeEx = "Leaf"
		pEl.Update
	end if
	pEl.Update
		
	dim el as EA.Element
	for each el in p.Elements
		If instr(el.StereoTypeEx,"Union") then
			el.StereoTypeEx = "Union"
		elseIf instr(el.StereoTypeEx,"type") then
			el.StereoTypeEx = "ISOTC211_CSL::type"
		end if
		el.Update
	next
	
	
	
	dim subP as EA.Package
	for each subP in p.packages
	    recPros(subP)
	next
end sub

sub main()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing then
		recPros(thePackage)
		
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main
