option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Control elements in diagrams
' Author: Knut Jetlund
' Purpose: controls if elements are present in any diagram in the selected package or any of 
'          it subpackages, and lists elements that are not present in any diagram. 
' Date: 20150702
'

' NOTE: Requires a package to be selected in the Project Browser
' 
' Related APIs
' =================================================================================
' Element API - http://www.sparxsystems.com/uml_tool_guide/index.html?element2.htm
'
dim lstDobj

'Recursive loop through subpackages, creating a list of all diagramobjects
sub recListDiagramObjects(p)
	Repository.WriteOutput "Script", Now & " Adding diagramobjects from package " & p.Name, 0 
	Repository.EnsureOutputVisible "Script"
	dim d as EA.Diagram
	dim Dobj as EA.DiagramObject
	for each d In p.diagrams
		'if Left(d.Name,7) = "Figure " then
			Repository.WriteOutput "Script", Now & " Adding diagramobjects from diagram " & d.Name, 0 
			for each Dobj in d.DiagramObjects
				If not lstDobj.ContainsKey(Dobj.ElementID) Then
				  lstDobj.Add Dobj.ElementID, Dobj.DiagramID
				end if   
			next	
		'end if	
	next
		
	dim subP as EA.Package
	for each subP in p.packages
	    recListDiagramObjects(subP)
	next
end sub

'Recursive loop through subpackages, listing elements that are not in a diagram
sub recElementNotInDiagram(p)
	Repository.WriteOutput "Script", Now & " Elements in package " & p.Name, 0  
	Repository.EnsureOutputVisible "Script"
	dim e as EA.Element
	for each e In p.elements
		If (e.Type="Class" or e.Type = "DataType") and not lstDobj.ContainsKey(e.ElementID) Then
			'Repository.WriteOutput "Error", e.Type & " not in diagram: " & p.Name & "." & e.Name, 0 
			Repository.WriteOutput "Error", "Package """ & p.Name & """, " & e.Type & " not in any diagram in the model: " & e.Name ,0	
			Repository.EnsureOutputVisible "Error"
		elseif e.Type="Object" and not lstDobj.ContainsKey(e.ElementID) Then 	
			'dim ce as EA.Element
			'set ce= Repository.GetElementByID(e.ClassifierID)
			'Repository.WriteOutput "Error", e.Type & " not in diagram: " & p.Name & "." & e.Name & " (instance of " & ce.Name & ")", 0 
			Repository.EnsureOutputVisible "Error"
		end if   
	next

	dim subP as EA.Package
	for each subP in p.packages
	    recElementNotInDiagram(subP)
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
		Set lstDobj = CreateObject( "System.Collections.Sortedlist" )
		Session.Output(Now & " Creating unique list of diagramobjects in package " & thePackage.Name) 
		recListDiagramObjects(thePackage)
		Session.Output(Now & " Controlling elements in package " & thePackage.Name) 
		recElementNotInDiagram(thePackage)
		Session.Output(Now & " Finished, check the Error tab")
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

ControlObjectsInDiagrams
