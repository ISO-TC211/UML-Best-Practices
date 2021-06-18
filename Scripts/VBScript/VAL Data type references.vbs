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

'Recursicve loop to get complete namespace
function namespaceString(element)
	dim elP as EA.Package
	set elP = Repository.GetPackageByID(element.PackageID)
	namespaceString = elP.Name
	
	dim parentId 
	parentId = elP.ParentID 
	do until parentId=0
		set elP = Repository.GetPackageByID(parentId)
		parentId = elP.ParentID 
		if parentId <> 0 then
			namespaceString = elP.Name & "." & namespaceString
		end if	
	loop

end function

'Recursive loop through subpackages and their elements, with controll of attributes
sub recListClassifier(p)
	dim lstEl
	Set lstEl = CreateObject("System.Collections.Sortedlist" )
	dim pStr, fullPath
	fullPath = namespaceString(p.Element)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	dim cEl as EA.Element
	for each el In p.elements
		Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
		if el.Type="Class" and UCase(el.Stereotype) <> "CODELIST" and el.Stereotype <> "enumeration" then
			dim attr as EA.Attribute
			for each attr in el.Attributes
				if attr.ClassifierID <> 0 then
					set cEl = Repository.GetElementByID(attr.ClassifierID)
					pStr = namespaceString(cEl)
					Repository.WriteOutput "Types", p.Name & "." & el.Name & "." & attr.Name & " (Data type: " & cEl.Name & " from package " & pStr & ")",0
					Repository.WriteOutput "TypesStructured", fullPath & ";" & p.Name & ";" & el.Name & ";" & attr.Name & ";" & pStr & ";" & cEl.Name,0
				else
					Repository.WriteOutput "Error", "Missing data type connection for attribute: " & el.Name & "." & attr.Name & " (Data type: " & attr.Type & ")",0
				end if
			next
			
			dim con as EA.Connector
			for each con in el.Connectors
				dim cEnd as EA.Connector
				if con.SupplierID = el.ElementID then
					set cEl = Repository.GetElementByID(con.ClientID)
					set cEnd = con.ClientEnd
				else
					set cEl = Repository.GetElementByID(con.SupplierID)
					set cEnd = con.SupplierEnd
				end if
								
				pStr = namespaceString(cEl)
				Repository.WriteOutput "TypesStructured", fullPath & ";" & p.Name & ";" & el.Name & ";" & cEnd.Role & ";" & pStr & ";" & cEl.Name,0
					
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
	Repository.CreateOutputTab "TypesStructured"
	Repository.ClearOutput "TypesStructured"
	
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
	
		Repository.WriteOutput "TypesStructured", "FullPath;Package;Element;Property;DependentPackage;DependendElement",0
		

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
