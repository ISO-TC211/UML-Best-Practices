option explicit

!INC Local Scripts.EAConstants-VBScript

'
' This code has been included from the default Workflow template.
' If you wish to modify this template, it is located in the Config\Script Templates
' directory of your EA install path.   
'
' Script Name: Missing definitions
' Author: Knut Jetlund
' Purpose: List elements and attributes without definitions
' Date: 20150708
'
' NOTE: Requires a package to be selected in the Project Browser

'Recursive loop through subpackages and their elements and attributes, with controll of missing definitions
sub recListMissingDefinitions(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		if el.Type="Class" then 
			Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
			if el.Notes = "" then
				Repository.WriteOutput "Error", "Missing definition for " & el.Type & " in package """ & p.Name & """: " & el.Name,0
			end if
			dim attr as EA.Attribute
			for each attr in el.Attributes
				Repository.WriteOutput "Script", Now & " " & el.Name & "." & attr.Name, 0
				if attr.Notes = "" then
					if el.Stereotype = "codeList" or el.Stereotype = "CodeList" or el.Stereotype = "enumeration" then
						Repository.WriteOutput "Error", "Missing definition for code value in package """ & p.Name & """: " & el.Name & "." & attr.Name,0	
				    else
						Repository.WriteOutput "Error", "Missing definition for attribute in package """ & p.Name & """: " & el.Name & "." & attr.Name,0
					end if	
				end if
			next
			dim con as EA.Connector
			for each con in el.Connectors
				if con.Type = "Aggregation" or con.Type = "Association" then
					dim ce as EA.ConnectorEnd
					dim oppositeElId
					if con.SupplierID = el.ElementID then
						set ce = con.ClientEnd
						oppositeElId = con.ClientID
					else
						set ce = con.SupplierEnd
						oppositeElId = con.SupplierID
					end if	
					dim oppositeElement as EA.Element
					set oppositeElement = Repository.GetElementByID(oppositeElId)
					if ce.Navigable = "Navigable" and ce.Role ="" then Repository.WriteOutput "Error", "Missing role name for " & ce.Navigable & " association in package """ & p.Name & """: " & el.Name & "." & ce.Role & " (towards " & oppositeElement.Name & ")",0	
					if ce.Navigable = "Navigable" and ce.RoleNote ="" then Repository.WriteOutput "Error", "Missing role definition for " & ce.Navigable & " association  in package """ & p.Name & """: " & el.Name & "." & ce.Role  & " (towards " & oppositeElement.Name & ")",0
				end if
				
			next
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recListMissingDefinitions(subP)
	next
end sub

sub ControllClassifierID()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recListMissingDefinitions(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

ControllClassifierID
