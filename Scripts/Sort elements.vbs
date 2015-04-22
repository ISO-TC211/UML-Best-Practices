option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Sort elements
' Author: Knut Jetlund
' Purpose: Sort elements in a package: (1) feature types (2) data types (3) code lists + alphabetaically within each group
' Date: 20150313
'

' NOTE: Requires a package to be selected in the Project Browser
' 
' Related APIs
' =================================================================================
' Element API - http://www.sparxsystems.com/uml_tool_guide/index.html?element2.htm
'
'Recursive loop through subpackages, with sorting of elements in package
sub recSortSubPackages(p)
	dim lstEl
	Set lstEl = CreateObject( "System.Collections.Sortedlist" )
	Session.Output(Now & " Package: " & p.Name)
	dim el as EA.Element
	for each el In p.elements
		select case el.Stereotype
			case "featureType": lstEl.Add "1." & el.name, el.ElementID
			case "Vegobjekttype": lstEl.Add "1." & el.name, el.ElementID
			case "dataType": lstEl.Add "2." & el.name, el.ElementID			
			case "codeList": lstEl.Add "3." & el.name, el.ElementID			
			case "Tillatte verdier": lstEl.Add "3." & el.name, el.ElementID			
			case else
				Session.Output(el.Stereotype & "." & el.name)
				'lstEl.Add "4." & el.name, el.ElementID			
		end select
		Session.Output(el.Stereotype & "." & el.name)
	next
			
	dim i
	for i = 0 To lstEl.Count - 1
		set el=Repository.GetElementByID(lstEl.GetByIndex(i))
		el.TreePos=i+1
		el.Update			
		Session.Output("Element: " & el.Name & " New position: " & i)
	next	
	Set lstEl = Nothing
	Repository.RefreshModelView (p.PackageID)
	
	dim subP as EA.Package
	for each subP in p.packages
	    recSortSubPackages(subP)
	next
end sub

sub SortElementsInPackage()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recSortSubPackages(thePackage)
		Session.Output( "Done!" )
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

SortElementsInPackage
