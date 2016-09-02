option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: Change data type references
' Author: Knut Jetlund
' Purpose: Remove reference to selected feature type
' Date: 20150422
'
' NOTE: Requires a package to be selected in the Project Browser

Const sID = 129241

'Recursive loop through subpackages and their elements, with controll of attributes
sub recRemoveConnector(p)
	dim lstEl
	Set lstEl = CreateObject("System.Collections.Sortedlist" )
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		if el.Stereotype = "featureType" or el.Stereotype = "FeatureType" then
			Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
			dim cNr 
			cNr = 0
			dim con as EA.Connector
			for each con in el.Connectors
				if con.SupplierID = sID or con.ClientID = sID then
					Repository.WriteOutput "Connectors", "Remove connector: " & p.Name & "." & el.Name & " (Type: " & con.Type  & ")" & " ClientID: " & con.ClientID  & " SupplierID: " & con.SupplierID,0
					el.Connectors.DeleteAt cNr,false
				end if	
				Repository.WriteOutput "Connectors", p.Name & "." & el.Name & " (Type: " & con.Type  & ")" & " ClientID: " & con.ClientID  & " SupplierID: " & con.SupplierID & " nr:" & cNr,0
				cNr = cNr + 1
			next
			el.Connectors.Refresh 
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recRemoveConnector(subP)
	next
end sub

sub main()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Connectors"
	Repository.ClearOutput "Connectors"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recRemoveConnector(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main
