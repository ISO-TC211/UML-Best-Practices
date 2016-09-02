option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: FeatureType to DataType
' Author: Knut Jetlund
' Purpose: Change selected feature types to data types
' Date: 20160624
'
' NOTE: Requires a package to be selected in the Project Browser
' 
'Recursive loop through subpackages, and do the thing
sub createLists(lstFt, lstAttr)
'Lists of feature types to change, and attributes to remove
	lstFT.Add "Dokumentasjon"
	lstFT.Add "Kommentar"
	lstFT.Add "TilstandSkadeFUPunkt"
	lstFT.Add "TilstandSkadeBelysning"
	
	lstAttr.Add "felt"
	lstAttr.Add "posisjon"
end sub

sub recPros(p)
	dim lstFT
	Set lstFT = CreateObject("System.Collections.ArrayList")
	dim lstAttr
	Set lstAttr = CreateObject("System.Collections.ArrayList")
	createLists lstFT, lstAttr

	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		if el.Stereotype = "featureType" or el.Stereotype = "FeatureType" then
			'Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name & "(" & el.ElementID & ")", 0
			if lstFT.Contains(el.Name) then
				Repository.WriteOutput "Script", Now & " Change stereotype: " & el.Stereotype & " " & el.Name & "(" & el.ElementID & ")", 0
				el.StereotypeEx = ""
				el.StereotypeEx = "dataType"
				el.Update 
				dim aNr 
				aNr=0
				dim attr as EA.Attribute
				for each attr in el.Attributes
				  if lstAttr.Contains(attr.Name) then
					Repository.WriteOutput "Script", Now & " Remove attribute: " & el.Name & "." & attr.Name , 0
				    el.Attributes.DeleteAt aNr,false
				  end if
				  aNr = aNr + 1
				next
				el.Attributes.Refresh
			end if
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
