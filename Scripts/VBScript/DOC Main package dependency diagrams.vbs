option explicit

!INC Local Scripts.EAConstants-VBScript
!INC HMMG.DOC_Dependencies_common

' Script Name: Main package dependency diagrams
' Author: Knut Jetlund
' Purpose: Aggregate dependencies up to the level of standards.
' Date: 20210115


sub level2DependencyDiagrams
	'Create level 2 dependency diagrams 
	Repository.WriteOutput "Script", Now & " " ,0
	dim i, j, keyIndex
	dim guid, parentGuid, level2Guid
	dim level, parentLevel
	dim currentPck as EA.Package
	dim con as EA.Connector
	dim depEl as EA.Element
	dim depPck as EA.Package
	
	For i = 0 To lstPck.Count - 1
		guid = lstPck.GetKey(i)
		level = lstPck.GetByIndex(i)	
		if level < 3 then
			set currentPck = Repository.GetPackageByGUID(guid)
		
			'Package dependency diagram - Delete old and create new
			dim eDiagram as EA.Diagram
			For j = 0 to currentPck.Diagrams.Count - 1
				set eDiagram = currentPck.Diagrams.GetAt(j)
				If eDiagram.Name = "Generated standards package dependencies" Then
					Repository.WriteOutput "Script", Now & " Delete diagram " & eDiagram.Name,0
					currentPck.Diagrams.DeleteAt j, False
				else
					Repository.WriteOutput "Special", Now & " Keep diagram " & eDiagram.Name,0		
				End If
			Next
			currentPck.Diagrams.Refresh
			Repository.WriteOutput "Script", Now & " Create dependency diagram for " & currentPck.Name,0		
			set pckDiagram = currentPck.Diagrams.AddNew("Generated standards package dependencies", "Package")
			pckDiagram.ShowPackageContents=False
			pckDiagram.HighlightImports=True
			pckDiagram.Update

			'Add main package to diagram
			set pckDiagramObject = pckDiagram.DiagramObjects.AddNew("", "")
			pckDiagramObject.ElementID = currentPck.Element.ElementID
			pckDiagramObject.ShowPackageAttributes = False
			pckDiagramObject.ShowPublicAttributes = False
			pckDiagramObject.ShowPrivateAttributes= False
			pckDiagramObject.ShowProtectedAttributes= False
			pckDiagramObject.Update()
			
			'Loop for registered dependencies - add to diagram	if package at level 0, 1 or 2
			for each con in currentPck.Connectors		
				set depEl = nothing
				If con.Type="Dependency" then 
					if con.SupplierID <> currentPck.Element.ElementID then
						set depEl = Repository.GetElementByID(con.SupplierID)
					elseif con.ClientID <> currentPck.Element.ElementID then
						set depEl = Repository.GetElementByID(con.ClientID)
					end if
				
					if not depEl is nothing then
						if depEl.Type = "Package" then 
							keyIndex = lstPck.IndexofKey(depEl.ElementGUID)
							if not keyINdex = -1 then
								level = lstPck.GetByIndex(keyIndex)
								'Add package to diagram if level 2, 1 or 0
								If level < 3 then 
									set depPck = Repository.GetPackageByGUID(depEl.ElementGUID)
									Repository.WriteOutput "Script", Now & " Adding package " & depPck.Name,0		
									set pckDiagramObject = pckDiagram.DiagramObjects.AddNew("", "")
									pckDiagramObject.ElementID = depEl.ElementID
									pckDiagramObject.ShowPackageAttributes = False
									pckDiagramObject.ShowPublicAttributes = False
									pckDiagramObject.ShowPrivateAttributes= False
									pckDiagramObject.ShowProtectedAttributes= False			
									pckDiagramObject.Update()
								end if
							else
								Repository.WriteOutput "Special", Now & " Depending package not in level 2 list: " & depEl.Name, 0
							end if	
						end if		
					end if	
				end if	
			Next
					'
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
						Repository.WriteOutput "Script", Now & " Not calculated connector" ,0
					end if
					'Hide connector that are not related to the current package
					if con.ClientID = currentPck.Element.ElementID or con.SupplierID = currentPck.Element.ElementID then
						dConnector.IsHidden = False
					else
						dConnector.IsHidden = True
					End If
					dConnector.Update()
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
	Next

end sub


sub MainPackageDependencies()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Types"
	Repository.ClearOutput "Types"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
	Repository.CreateOutputTab "Special"
	Repository.ClearOutput "Special"
		
	' Get the currently selected package in the tree to work on
	dim theModel as EA.Package
	set theModel = Repository.Models.GetByName("Conceptual Models")
	
	Set lstPck = CreateObject("System.Collections.SortedList" )
	Set lstPckElement = CreateObject("System.Collections.SortedList" )
	dim thePackage as EA.Package
	
	For each thePackage in theModel.Packages
		'set thePackage = Repository.GetTreeSelectedPackage()
		recPackageLevelList thePackage, 0
	next
	
	set thePackage = theModel.Packages.GetByName("ISO TC211")
	level2DependencyDiagrams

	Repository.WriteOutput "Script", Now & " " ,0
	Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
	Repository.EnsureOutputVisible "Script"
end sub

MainPackageDependencies
