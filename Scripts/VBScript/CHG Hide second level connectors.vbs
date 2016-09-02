option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: Hide second level connectors
' Author: Knut Jetlund
' Purpose: Hide connectors in the diagrams that are not connected to a feature type in the package
' Date: 20160624
'
' NOTE: Requires a package to be selected in the Project Browser
' 

'Recursive loop through subpackages, and do the thing
sub recPros(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		if el.Stereotype = "featureType" or el.Stereotype = "FeatureType" then
			Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name & "(" & el.ElementID & ")", 0
						
			dim d as EA.Diagram
			for each d in p.Diagrams
				Repository.WriteOutput "Script", Now & " Diagram " & " " & d.Name, 0
				dim dCon as EA.DiagramLink
				for each dCon in d.DiagramLinks
					dim con as EA.Connector
					set con = Repository.GetConnectorByID(dCon.ConnectorID)
					dim elA as EA.Element
					set elA = Repository.GetElementByID(con.ClientID)
					dim elB as EA.Element
					set elB = Repository.GetElementByID(con.SupplierID)
					if con.ClientID = el.ElementID or con.SupplierID = el.ElementID then
						dCon.IsHidden = False
						Repository.WriteOutput "Connectors", Now & " Show connector: " & d.Name & " "  & dCon.ConnectorID & " " & elA.Name & " - " & elB.Name, 0
					else
						dCon.IsHidden = True
						Repository.WriteOutput "Connectors", Now & " Hide connector: " & d.Name & " "  & dCon.ConnectorID & " " & elA.Name & " - " & elB.Name, 0
					end if					
					dCon.Update()
				next
				d.DiagramLinks.Refresh
				d.Update
			next
			
		end if
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
	Repository.CreateOutputTab "Connectors"
	Repository.ClearOutput "Connectors"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
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
