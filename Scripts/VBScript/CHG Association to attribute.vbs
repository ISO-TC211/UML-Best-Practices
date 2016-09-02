option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: Association to attribute 
' Author: Knut Jetlund
' Purpose: Change from associated data types to attributes
' Date: 20160627
'
' NOTE: Requires a package to be selected in the Project Browser
' 

'Recursive loop through subpackages, and do the thing
sub recPros(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		dim cNr
		cNr = 0
		dim con as EA.Connector
		for each con in el.Connectors
			if con.Type = "Aggregation" or con.Type = "Association" then
				dim assEl as EA.Element
				dim card 
				if con.SupplierID = el.ElementID then
					set assEl = Repository.GetElementByID(con.ClientID)
					card = con.SupplierEnd.Cardinality
'				else
'					set assEl = Repository.GetElementByID(con.ClientID)
'					card = con.ClientEnd.Cardinality
'				end if		
					if assEl.Stereotype = "dataType" then
						Repository.WriteOutput "Script", Now & " Change to attribute: " & el.Stereotype & " " & el.Name & " (" & el.ElementID & ")" & " associaton to " & assEl.Stereotype & " " & assEl.Name & " (" & assEl.ElementID & " " & card & ")" , 0
						'Find max Pos for attributes in element
						dim maxPos
						maxPos = 0
						dim attr as EA.Attribute
						for each attr in el.Attributes
							if attr.Pos > maxPos then
								maxPos = attr.Pos
							end if	
						next
						'lowerCase first character in name
						dim aName
						aName = LCase(Left(assEl.Name,1)) & Mid(assEl.Name,2)			
						'add attribute at last position
						set attr = el.Attributes.AddNew (aName, assEl.Name)
						attr.ClassifierID = assEl.ElementID
						attr.Pos=maxPos + 1
						attr.Update
						'remove connector
						el.Connectors.DeleteAt cNr, false
					end if
				end if
			end if	
			cNr = cNr + 1
		next
		el.Attributes.Refresh
		el.Connectors.Refresh
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
