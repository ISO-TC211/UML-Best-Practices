option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Duplicate element names
' Author: Knut Jetlund
' Purpose: Searches for duplipacte element names within each subpackage of a selected package 
' Date: 20150702
'

' NOTE: Requires a package to be selected in the Project Browser
' 
' Related APIs
' =================================================================================
' Element API - http://www.sparxsystems.com/uml_tool_guide/index.html?element2.htm
'


'Recursive loop through subpackages, listing duplicate element names
sub recDuplicateElement(p)
	dim lstEl
	Set lstEl = CreateObject( "System.Collections.Sortedlist" )
	Repository.WriteOutput "Script", Now & " Elements in package " & p.Name, 0  
	Repository.EnsureOutputVisible "Script"
	dim e as EA.Element
	for each e In p.elements
		If e.Type="Class" or e.Type="Object" then
			dim strName 
			if e.Type = "Class" then
			  strName=e.Name
			elseif e.Type = "Object" then
				dim ce as EA.Element
				set ce= Repository.GetElementByID(e.ClassifierID)
				strName = e.Name & ":" & ce.Name
			end if
			Repository.WriteOutput "Script", Now & " Element: " & p.Name & "." & strName, 0  
			Repository.EnsureOutputVisible "Script"
		 
			if lstEl.ContainsKey(strName) then
				Repository.WriteOutput "Error", "Duplicate " & e.Type & " name: " & p.Name & "." & strName, 0 
				'Repository.EnsureOutputVisible "Error"
			else
				lstEl.Add strName, e.ElementID
			end if
		end if
	next

	dim subP as EA.Package
	for each subP in p.packages
	    recDuplicateElement(subP)
	next
end sub

sub ControlObjectsInDiagrams()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		Session.Output(Now & " Controlling elements in package " & thePackage.Name) 
		recDuplicateElement(thePackage)
		Session.Output(Now & " Finished, check the Error tab")
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

ControlObjectsInDiagrams
