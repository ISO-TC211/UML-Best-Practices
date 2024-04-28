option explicit

!INC Local Scripts.EAConstants-VBScript

'
' This code has been included from the default Workflow template.
' If you wish to modify this template, it is located in the Config\Script Templates
' directory of your EA install path.   
'
' Script Name: Change connector properties
' Author: Knut Jetlund
' Purpose: Change properties for connectors
' Date: 20220804
'
' NOTE: Requires a package to be selected in the Project Browser

'Tests:
'ianu = The element is an object (instance) and the connector end is a shared aggregation --> set navigability to unspecified
'cgsu = The element is a class, the connector is a generalization --> set isSubstitutable to true

const testid = "cgsu"

'Recursive loop through subpackages and their elements and attributes, with controll of missing definitions
sub recListMissingDefinitions(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
			Repository.WriteOutput "Script", Now & " " & el.Type & " " & el.Name, 0
			dim con as EA.Connector
			for each con in el.Connectors
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
				
				dim agg
				select case ce.Aggregation
					case  0: agg="None"
					case  1: agg="Shared"
					case  2: agg="Composite"
				end select
				Repository.WriteOutput "Script", ce.Navigable & " " & con.Type & " connector in package """ & p.Name & """: " & el.Name & " towards " & oppositeElement.Name & " Aggregation: " & agg & " Role: " & ce.Role,0	
				
				'Requirement tests and change
				if testid = "ianu" then 
					if el.Type = "Object" and (con.Type = "Aggregation" or con.Type = "Association") and ce.Aggregation = 2 then
						ce.Navigable = "Non-Navigable"
						ce.Update
						ce.Navigable = "Unspecified"
						ce.Update
						Repository.WriteOutput "Changes", "Set to unspecified navigability: " & ce.Navigable & " association in package """ & p.Name & """: " & el.Name & " towards " & oppositeElement.Name & " Aggregation: " & agg & " Role: " & ce.Role,0	
					end if
				elseif testid = "cgsu" then
					if el.Type = "Class" and (con.Type = "Generalization" or con.Type = "Generalisation") then
						dim cp as EA._CustomProperty
						for each cp in con.CustomProperties
							Repository.WriteOutput "Script", "Custom property name: " & cp.Name & " value: " & cp.Value,0	
							if cp.Name = "isSubstitutable"	then
								cp.Value = -1
								con.Update
								Repository.WriteOutput "Changes", "Set 'isSubstitutable' to false: " & con.Type & " in package """ & p.Name & """: " & el.Name & " towards " & oppositeElement.Name,0								
							end if
						next
					end if
			
				end if	
										
					
			next
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
	Repository.CreateOutputTab "Changes"
	Repository.ClearOutput "Changes"
	
		
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
