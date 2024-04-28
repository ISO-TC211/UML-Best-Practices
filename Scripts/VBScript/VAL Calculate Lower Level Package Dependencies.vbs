option explicit

!INC Local Scripts.EAConstants-VBScript
!INC HMMG.DOC_Dependencies_common

' Script Name: Calculate package dependencies
' Author: Knut Jetlund
' Purpose: Recursive loop through all subpackages and their elements, with controll of dependencies at the lowest level
' Date: 20210115

dim el as EA.Element


sub getDependency
	'Repository.WriteOutput "Script", Now & " Connected element: " & elID,0
	dim cEl as EA.Element
	set cEl = Repository.GetElementByID(elID)

	dim dtP as EA.Package
	if cEl.Type = "Package" then 
		set dtP = Repository.GetPackageByGUID(cEl.ElementGUID)	
		if dtP.PackageGUID <> currentPck.PackageGUID then Repository.WriteOutput "Packages", Now & " " & currentPck.Name & "." & el.Name & " directly depending on package: " & dtP.Name,0
	else
		set dtP = Repository.GetPackageByID(cEl.PackageID)
		if dtP.PackageGUID <> currentPck.PackageGUID then Repository.WriteOutput "Packages", Now & " " & currentPck.Name & "." & el.Name & " depending on element: " & dtP.Name & "." & cEl.Name,0
	end if	
	
	
	'Process only packages that are not already processed for the current package
	if not lstPck.Contains(dtP.PackageGUID) and dtP.PackageGUID <> currentPck.PackageGUID then
		lstPck.Add dtP.PackageGUID, currentPck.PackageGUID
		'Repository.WriteOutput "Script", Now & " Package dependency to: " & dtP.Name,0

		dim hasDependency
		hasDependency = false
		For each pckConnector in currentPck.Connectors
			if (pckConnector.Type="Dependency" OR pckConnector.Type="Usage") AND pckConnector.SupplierID = dtP.Element.ElementID then 
				pckConnector.Notes = "Calculated"
				pckConnector.Update
				hasDependency = true
				Repository.WriteOutput "Packages", Now & " Updating package dependency to: " & dtP.Name,0
			end if	
		next
		if hasDependency = false then
			set pckConnector = currentPck.Connectors.AddNew("","Dependency")
			pckConnector.SupplierID = dtP.Element.ElementID
			pckConnector.Notes = "Calculated"
			pckConnector.Update
			Repository.WriteOutput "Packages", Now & " Adding package dependency to: " & dtP.Name,0
		end if
	end if
end sub

sub recCalculateDependencies(p)
	'Loop through attributes and connectors for all elements, to identify dependencies to other packages
	Repository.WriteOutput "Script", Now & " " ,0
	Repository.WriteOutput "Elements", Now & " " ,0
	Repository.WriteOutput "Error", Now & " " ,0
	Repository.WriteOutput "Error", Now & " Package: " & p.Name, 0
	Repository.WriteOutput "Script", Now & " ---------------------- ", 0
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	Repository.WriteOutput "Packages", Now & " Package: " & p.Name, 0
	
	set currentPck = p
	'Start new list of related packages
	Set lstPck = CreateObject("System.Collections.SortedList" )

	'Find dependencies for each class and interface
	for each el In currentPck.elements
		if (el.Type="Class" or el.Type="Interface") and Ucase(el.Stereotype) <> "CODELIST" and UCase(el.Stereotype) <> "ENUMERATION" and UCase(el.Stereotype) <> "UNION" then
			Repository.WriteOutput "Script", Now & " Element: """ & el.Stereotype & """ " & el.Name & " " & el.ElementID, 0
	
			
			'Analyse attribute dependencies
			dim attr as EA.Attribute
			for each attr in el.Attributes
				elID = attr.ClassifierID
				if attr.ClassifierID <> 0 then
					Repository.WriteOutput "Script", Now & " Attribute: " &  attr.Name & ", type: " & elID , 0			
					Repository.WriteOutput "Elements", Now & " |" & currentPck.Name & "|" & el.Stereotype & "|" & el.Name & "|Attribute|" &  attr.Name & "|" & elID & "|", 0
					getDependency()
				else
					Repository.WriteOutput "Error", Now & " Missing data type connection for attribute: " & currentPck.Name & "." & el.Name & "." & attr.Name & " (Data type: " & attr.Type & ")",0
				end if
			next
			
			'Analyse connector dependencies
			dim con as EA.Connector
			for each con in el.Connectors
				elID = 0
				'Generalization and Realization
				'Not subtyping - only generalization gives dependency
				If (con.Type="Generalization" or con.Type="Realization") and con.ClientID=el.ElementID then			
					elID = con.SupplierID
				'Aggregation and association
				'Direction = Source -> Destination and SupplierID = el.ElementID
				'Direction = Destination -> Source and ClientID = el.ElementID
				'Bidirectional or Unspecified - dependency on both sides
				elseif (con.Type="Aggregation" or con.Type="Association") and _
				(con.Direction = "Source -> Destination" and con.SupplierID = el.ElementID) then
					'Repository.WriteOutput "Script", Now & " Association (" & con.Direction & ") to " & con.ClientID, 0
					elID = con.SupplierID			
				elseif (con.Type="Aggregation" or con.Type="Association") and _
				(con.Direction = "Destination -> Source" and con.ClientID = el.ElementID) then
					'Repository.WriteOutput "Script", Now & " Association (" & con.Direction & ") to " & con.SupplierID, 0		
					elID = con.ClientID
				elseif (con.Type="Aggregation" or con.Type="Association") and _
				(con.Direction = "Bidirectional" or con.Direction="Unspecified") and con.ClientID = el.ElementID then
					'Repository.WriteOutput "Script", Now & " Association (" & con.Direction & ") to " & con.SupplierID, 0
					elID = con.SupplierID
				elseif (con.Type="Aggregation" or con.Type="Association") and _
				(con.Direction = "Bidirectional" or con.Direction="Unspecified") and con.SupplierID = el.ElementID then
					'Repository.WriteOutput "Script", Now & " Association (" & con.Direction & ") to " & con.ClientID, 0
					elID = con.ClientID			
				end if
				If not elID = 0 and elID <> el.ElementID then
					Repository.WriteOutput "Elements", Now & " |" & currentPck.Name & "|" & el.Stereotype & "|" & el.Name & "|" & con.Type & "||" & elID & "|", 0
					Repository.WriteOutput "Script", Now & " " & con.Type & " to " & elID, 0
					getDependency()
				end if	
			next			
		end if
	next

	dim subP as EA.Package
	for each subP in p.packages
	    recCalculateDependencies(subP)
	next
end sub

sub recDependencyDiagrams(p)
	Repository.WriteOutput "Script", Now & " " ,0
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0

	Repository.WriteOutput "Packages", Now & " " ,0
	Repository.WriteOutput "Packages", Now & " Package: " & p.Name, 0
	Repository.WriteOutput "Elements", Now & " " ,0
	Repository.WriteOutput "Elements", Now & " Package: " & p.Name, 0

	dim i
	'Package dependency diagram - Delete old and create new
	dim eDiagram as EA.Diagram
	For i = 0 to p.Diagrams.Count - 1
		set eDiagram = p.Diagrams.GetAt(i)
		If eDiagram.Name = "Generated lowest level package dependencies" Then
			Repository.WriteOutput "Script", Now & " Delete diagram " & eDiagram.Name,0
			p.Diagrams.DeleteAt i, False
		else
			'Repository.WriteOutput "Script", Now & " Keep diagram " & eDiagram.Name,0		
		End If
	Next
	p.Diagrams.Refresh
	
	'Add diagram only for lowest level packages
	if 	p.Packages.Count = 0 then
		set pckDiagram = p.Diagrams.AddNew("Generated lowest level package dependencies", "Package")
		pckDiagram.ShowPackageContents=False
		pckDiagram.HighlightImports=True
		pckDiagram.Update
		Repository.WriteOutput "Script", Now & " Create diagram " & pckDiagram.Name,0		

		'Add main package to diagram
		set pckDiagramObject = pckDiagram.DiagramObjects.AddNew("", "")
		pckDiagramObject.ElementID = p.Element.ElementID
		pckDiagramObject.ShowPackageAttributes = False
		pckDiagramObject.ShowPublicAttributes = False
		pckDiagramObject.ShowPrivateAttributes= False
		pckDiagramObject.ShowProtectedAttributes= False
		pckDiagramObject.Update()

		dim con as EA.Connector
		dim depPEl as EA.Element
		'Loop for registered dependencies - add all dependent packages to diagram	
		Repository.WriteOutput "Packages", Now & " Package dependencies for " & p.Name ,0
		for each con in p.Connectors
			set depPEl = nothing
			if con.SupplierID <> p.Element.ElementID then
				set depPEl = Repository.GetElementByID(con.SupplierID)
			elseif con.ClientID <> p.Element.ElementID then
				set depPEl = Repository.GetElementByID(con.ClientID)
			end if
			
			if not depPEl is nothing then
				Repository.WriteOutput "Packages", Now & " Package dependency between " & p.Name & " and " & depPEl.Name,0
				set pckDiagramObject = pckDiagram.DiagramObjects.AddNew("", "")
				pckDiagramObject.ElementID = depPEl.ElementID
				pckDiagramObject.ShowPackageAttributes = False
				pckDiagramObject.ShowPublicAttributes = False
				pckDiagramObject.ShowPrivateAttributes= False
				pckDiagramObject.ShowProtectedAttributes= False			
				pckDiagramObject.Update()
			end if	
		Next
		
		'Loop for diagramlinks - set red if not calculated
		dim dConnector as EA.DiagramLink
		for each dConnector in pckDiagram.DiagramLinks
			set con = Repository.GetConnectorByID(dConnector.ConnectorID)
			if not con is nothing then
				if con.Notes = "Calculated" then
					'Set color = Green
					'dConnector.LineColor = 
				else
					'Set color = Red
					dConnector.LineColor = 255
					dConnector.Update
					Repository.WriteOutput "Script", Now & " Not calculated connector" ,0
				end if
			end if
		next	
		pckDiagram.Update
		
		'Layout		
		pckDiagram.Update		
		dim ePIF as EA.Project
		set ePIF = Repository.GetProjectInterface
		ePIF.LayoutDiagramEx pckDiagram.DiagramGUID, 4, 4, 20, 20, True
		repository.CloseDiagram(pckDiagram.DiagramID)			
	end if
	
	dim subP as EA.Package
	for each subP in p.packages
		recDependencyDiagrams(subP)
	next

end sub


sub PackageDependencies()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Elements"
	Repository.ClearOutput "Elements"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
	Repository.CreateOutputTab "Packages"
	Repository.ClearOutput "Packages"
		
	' Get the currently selected package in the tree to work on
	dim theModel as EA.Package
	set theModel = Repository.Models.GetByName("Conceptual Models")
	'set theModel = Repository.GetTreeSelectedPackage()
	
	dim thePackage as EA.Package
	Repository.WriteOutput "Elements", Now & " |Package|ElementType|Element|PropertyType|Property|DependentElementID|", 0

	For each thePackage in theModel.Packages
		recCalculateDependencies(thePackage)
		recDependencyDiagrams(thePackage)
	next
		
		Repository.WriteOutput "Script", Now & " " ,0
		Repository.WriteOutput "Script", Now & " Finished, check the Error tab", 0 
		Repository.EnsureOutputVisible "Script"
end sub

PackageDependencies
