option explicit

!INC Local Scripts.EAConstants-VBScript

'
' This code has been included from the default Workflow template.
' If you wish to modify this template, it is located in the Config\Script Templates
' directory of your EA install path.   
'
' Script Name: Control data type connection
' Author: Knut Jetlund
' Purpose: Controls that attributes are really connectdet to data types and code lists (ClassifierID)
' Date: 20150422
'
' NOTE: Requires a package to be selected in the Project Browser

'Recursive loop through subpackages and their elements, with controll of attributes
sub recControllClassifierID(p)
	dim lstEl
	Set lstEl = CreateObject("System.Collections.Sortedlist" )
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
		if el.Stereotype <> "codeList" and el.Stereotype <> "enumeration" then
			dim attr as EA.Attribute
			for each attr in el.Attributes
				Repository.WriteOutput "Script", Now & " Attribute: " & el.Name & "." & attr.Name & " (Data type: " & attr.Type & ")",0
				if attr.ClassifierID = 0 then
					Repository.WriteOutput "Error", Now & " Missing data type connection for attribute: " & el.Name & "." & attr.Name & " (Data type: " & attr.Type & ")",0
				end if
			next
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recControllClassifierID(subP)
	next
end sub

sub ControllClassifierID()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Error"
	'Repository.EnsureOutputVisible("Error")	
	Repository.ClearOutput("Error")
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recControllClassifierID(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Error tab", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

ControllClassifierID
