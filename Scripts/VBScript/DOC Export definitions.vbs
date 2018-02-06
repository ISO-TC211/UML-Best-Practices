option explicit

!INC Local Scripts.EAConstants-VBScript

'
' This code has been included from the default Workflow template.
' If you wish to modify this template, it is located in the Config\Script Templates
' directory of your EA install path.   
'
' Script Name: Export definitions
' Author: Knut Jetlund
' Purpose: Exports element and attributes definitions to CSV file
' Date: 20150708
'
' NOTE: Requires a package to be selected in the Project Browser

const path = "C:\DATA\GitHub\ISO19111\Definitions\"
dim objFSO, objDefFile

'Recursive loop through subpackages and their elements and attributes, with controll of missing definitions
sub recExportDefinitions(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		if el.Type="Class" then 'and el.Stereotype <> "codeList" and el.Stereotype <> "CodeList" and el.Stereotype <> "enumeration"
			'Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
			if el.Notes = "" then
				Repository.WriteOutput "Error", "Missing element definition: " & el.Name,0
			end if 
			objDefFile.Write p.Name & "|" & el.Name & "||" & el.Notes & vbCrLf 
			dim attr as EA.Attribute
			for each attr in el.Attributes
				'Repository.WriteOutput "Script", Now & " " & el.Name & "." & attr.Name, 0
				if attr.Notes = "" then
					if el.Stereotype = "codeList" or el.Stereotype = "CodeList" or el.Stereotype = "enumeration" then
						Repository.WriteOutput "Error", "Missing code value definition: " & el.Name & "." & attr.Name,0	
				    else
						Repository.WriteOutput "Error", "Missing attribute definition: " & el.Name & "." & attr.Name,0
					end if	
				end if
				objDefFile.Write p.Name & "|" & el.Name & "|" & attr.Name & "|" & attr.Notes & vbCrLf 
			next
			
			dim conn as EA.Connector
			dim cE as EA.ConnectorEnd
			for each conn in el.Connectors
				'find "the oposite" end of the association
				if conn.ClientID = el.ElementID then
					set cE = conn.SupplierEnd
				else
					set cE = conn.ClientEnd
				end if
				if cE.Navigable = "Navigable" and (conn.Type = "Aggregation" or conn.Type="Association") then
					Repository.WriteOutput "Script", Now & " " & el.Name & "." & cE.Role  & " - navigable", 0
					if cE.RoleNote = "" then
						Repository.WriteOutput "Error", "Missing association role definition: " & el.Name & "." & cE.Role & " (Type=" & conn.Type & ")",0	
				  	end if 
					objDefFile.Write p.Name & "|" & el.Name & "|" & cE.Role & "|" & cE.RoleNote & vbCrLf 
				end if 
			next
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recExportDefinitions(subP)
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
		Set objFSO=CreateObject("Scripting.FileSystemObject")
		Set objDefFile = objFSO.CreateTextFile(path & "\" & thePackage.Name & ".csv",True)
		objDefFile.Write "package|element|attribute|definition" & vbCrLf
		recExportDefinitions(thePackage)
		objDefFile.Close
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

ControllClassifierID
