option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Export diagrams as images
' Author: Knut Jetlund	
' Purpose: Export diagrams to image files. Uses alias as prefix.
' Date: 20150411
'
const path = "C:\DATA\GitHub\TN-ITS\Figures\"
const suffix = "PNG"
dim dgr as EA.Diagram

dim ePIF as EA.Project
'Save current diagram
sub saveDiagram(strName)
	dim fullName
	fullName=path & suffix & "\" & strName & "." & suffix
	Session.Output(Now & " Eksporter diagram: " & dgr.Name & " som " & fullName)
	ePIF.LoadDiagram(ePIF.GUIDtoXML(dgr.DiagramGUID))
	ePIF.SaveDiagramImageToFile(fullName)
	Repository.CloseDiagram(dgr.DiagramID)
end sub

'Recursive loop through all subpackages, with export from current package
sub recLoopSubPackages(p)
	Session.Output(Now & " Package: " & p.Name)
	for each dgr In p.diagrams
		'Prefix to diagram name
		dim strPre 
		strPre=p.Alias
	    Select Case dgr.Name
            Case p.Name & " Tillatte verdier" : SaveDiagram(p.Alias & "_UML_Tillatte_verdier")
            Case p.Name & " Assosiasjoner" : SaveDiagram(p.Alias & "_UML_Assosiasjoner")
            Case p.Name & " Betingelser" : SaveDiagram(p.Alias & "_UML_Betingelser")
            'Case p.Name & " Tillatte verdier" : SaveDiagram("Tillatte_verdier\" & p.Alias & "_UML_Tillatte_verdier")
            'Case p.Name & " Assosiasjoner" : SaveDiagram("Assosiasjoner\" & p.Alias & "_UML_Assosiasjoner")
            'Case p.Name & " Betingelser" : SaveDiagram("Betingelser\" & p.Alias & "_UML_Betingelser")
			Case else: SaveDiagram(dgr.Name)
        End Select
	next
	dim subP as EA.Package
	for each subP in p.packages
	    recLoopSubPackages(subP)
	next
end sub

'Find selected package, and start loop through package and subpackages
sub exportDiagramsFromPackage()

	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
	
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		set ePIF = Repository.GetProjectInterface
		recLoopSubPackages(thePackage)
		
		Session.Output(Now & " Ferdig!" )
		
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

exportDiagramsFromPackage
