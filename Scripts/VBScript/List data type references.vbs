option explicit

!INC Local Scripts.EAConstants-VBScript

'
' This code has been included from the default Workflow template.
' If you wish to modify this template, it is located in the Config\Script Templates
' directory of your EA install path.   
'
' Script Name: List data type references
' Author: Knut Jetlund
' Purpose: List name and package for referenced data types
' Date: 20150422
'
' NOTE: Requires a package to be selected in the Project Browser

'Recursive loop through subpackages and their elements, with controll of attributes
sub recListClassifier(p)
	dim lstEl
	Set lstEl = CreateObject("System.Collections.Sortedlist" )
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
		if el.Type="Class" and el.Stereotype <> "codeList" and el.Stereotype <> "CodeList" and el.Stereotype <> "enumeration" then
			dim attr as EA.Attribute
			for each attr in el.Attributes
				if attr.ClassifierID <> 0 then
					dim cEl as EA.Element
					set cEl = Repository.GetElementByID(attr.ClassifierID)
					dim dtP as EA.Package
					set dtP = Repository.GetPackageByID(cEl.PackageID)
					dim parentId 
					parentId = dtP.ParentID 
					dim pStr
					pStr = dtP.Name
					do until parentId=0
						set dtP = Repository.GetPackageByID(parentId)
						parentId = dtP.ParentID 
						if parentId <> 0 then
							pStr = dtP.Name & "." & pStr
						end if	
					loop
					Repository.WriteOutput "Types", p.Name & "." & el.Name & "." & attr.Name & " (Data type: " & cEl.Name & " from package " & pStr & ")",0
				else
					Repository.WriteOutput "Error", "Missing data type connection for attribute: " & el.Name & "." & attr.Name & " (Data type: " & attr.Type & ")",0
				end if
			next
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recListClassifier(subP)
	next
end sub

sub ControllClassifierID()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Types"
	Repository.ClearOutput "Types"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recListClassifier(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

ControllClassifierID
