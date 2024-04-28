
' Script Name: Dependencies common 
' Author: Knut Jetlund
' Purpose: Common functions for dependency analysis
' Date: 20210118

'List variables
dim lstPck, lstPckElement
'The package diagram
dim pckDiagram as EA.Diagram
'Objects in the package diagram 
dim pckDiagramObject as EA.DiagramObject
'Connectors in the package diagram
dim pckConnector as EA.Connector
'The current package
dim currentPck as EA.Package
'Elementidentifier for global use
dim elID 

sub recPackageLevelList(p, level)
'Create list of packages and their level in the model structure
	If level < 3 then 
		Repository.WriteOutput "Script", Now & " " ,0
	end if
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	Repository.WriteOutput "Script", Now & " Adding level " & level & " package to list: " & p.Name, 0
	lstPck.Add p.packageGUID, level

	dim subP as EA.Package
	for each subP in p.packages
	    recPackageLevelList subP, level+1
	next
end sub
