option explicit

!INC Local Scripts.EAConstants-VBScript
!INC HMMG.DOC_Dependencies_common

' Script Name: Aggregate main package dependencies
' Author: Knut Jetlund
' Purpose: Aggregate dependencies from lower level pa to the level of standards
' Date: 20151027
'


sub level2Dependencies
	'Aggregate all dependencies to level 2
	Repository.WriteOutput "Script", Now & " " ,0
	dim i, keyIndex
	dim guid, parentGuid, level2Guid
	dim level, parentLevel
	dim currentPck as EA.Package
	dim parentPck as EA.Package
	
	dim level2List 
	Set level2List = CreateObject("System.Collections.SortedList" )
	
	'Connect each package to its level 2 package
	For i = 0 To lstPck.Count - 1
		guid = lstPck.GetKey(i)
		level = lstPck.GetByIndex(i)
		set currentPck = Repository.GetPackageByGUID(guid)
		
		if level > 2 then
			'Find level 2 package for current package
			parentLevel = level
			do until parentLevel = 2
				set parentPck = Repository.GetPackageByID(currentPck.ParentID)
				keyIndex = lstPck.IndexofKey(parentPck.PackageGUID)
				parentLevel = lstPck.GetByIndex(keyIndex)
				set currentPck = Repository.GetPackageByGUID(parentPck.PackageGUID)
			loop
			set currentPck = Repository.GetPackageByGUID(guid)			
			Repository.WriteOutput "Script", Now & " Level 2 package: " & parentPck.Name & " for package " & currentPck.Name, 0
			'Add to list of level 2 packages
			level2List.Add currentPck.packageGUID, parentPck.PackageGUID
		else
			level2List.Add currentPck.packageGUID, currentPck.PackageGUID	
		end if
	Next


	'Connect each dependency to level 2 packages
	dim depList
	set depList = CreateObject("System.Collections.SortedList" )
	dim con as EA.Connector
	dim depEl as EA.Element
	dim depPck as EA.Package
	dim tmpPck as EA.Package
	
	For i = 0 To level2List.Count - 1
		guid = level2List.GetKey(i)
		set currentPck = Repository.GetPackageByGUID(guid)
		level2Guid = level2List.GetByIndex(i)
		set parentPck = Repository.GetPackageByGUID(level2Guid)
		Repository.WriteOutput "Script", Now & " ", 0
		Repository.WriteOutput "Script", Now & " Level 2 package: " & parentPck.Name & " for package " & currentPck.Name, 0
		Repository.WriteOutput "Types", Now & " Level 2 package: " & parentPck.Name & " for package " & currentPck.Name, 0

		dim ownRole
		'Loop for registered dependencies - aggregate to level 2	
		for each con in currentPck.Connectors
			if con.Type = "Dependency" or con.Type= "Usage" then
				'Find dependant element and define the role of the current package 
				set depEl = nothing
				if con.SupplierID <> currentPck.Element.ElementID then
					set depEl = Repository.GetElementByID(con.SupplierID)
					ownRole = "Client"
				elseif con.ClientID <> currentPck.Element.ElementID then
					set depEl = Repository.GetElementByID(con.ClientID)
					ownRole = "Supplier"
				end if
				
				if not depEl is nothing then 
					'Find direct depending package (tmpPck)
					Repository.WriteOutput "Script", Now & " Dependency to: " & depEl.Name, 0
					set tmpPck = nothing
					if depEl.Type = "Package" then 
						set tmpPck = Repository.GetPackageByGUID(depEl.ElementGUID)
					else
						'Depending element is not a package, get the package
						set tmpPck = Repository.GetPackageByID(depEl.PackageID)
					end if	
					
					if not tmpPck is nothing then
						'Find level 2 package for direct depending package (tmpPck)				
						keyIndex = level2List.IndexofKey(tmpPck.PackageGUID)
						if not keyIndex = -1 then
							guid = level2List.GetByIndex(keyIndex)	
							set depPck = Repository.GetPackageByGUID(guid)				
							if depPck.PackageGUID <> parentPck.PackageGUID then 
								Repository.WriteOutput "Script", Now & " Depending package: " & depPck.Name & " for " & tmpPck.Name , 0
								Repository.WriteOutput "Types", Now & " Depending package: " & depPck.Name & " for " & tmpPck.Name , 0
								'Loop for current level 2 package (parentPck) - check for connector in the given direction to the depending level 2 package (depPck)
								dim parentCon as EA.Connector
								dim j
								dim parentConExists
								parentConExists = false
								for j = 0 to parentPck.Connectors.Count - 1
									set parentCon = parentPck.Connectors.GetAt(j)
									if (parentCon.Type = "Dependency" or parentCon.Type= "Usage") _ 
									and ((ownRole = "Client" and parentCon.ClientID = parentPck.Element.ElementID and parentCon.SupplierID = depPck.Element.ElementID) _
									or (ownRole = "Supplier" and parentCon.SupplierID = parentPck.Element.ElementID and parentCon.ClientID = depPck.Element.ElementID)) then
										parentConExists = true
										'Level 2 connector that aggregates the lower level dependency exists. Set level 2 connector to "Calculated" if the lower level connector is calculated
										if con.Notes = "Calculated" then 
											parentCon.Notes = "Calculated"
											parentCon.Update
										end if	
										j = parentPck.Connectors.Count - 1
									end if	
								next
								'Create missing dependencies at level 2
								if not parentConExists then
									Repository.WriteOutput "Types", Now & " Adding connector between: " & parentPck.Name & " and " & depPck.Name, 0
									set parentCon = parentPck.Connectors.AddNew("", "Dependency")
									if ownRole = "Client" then
										parentCon.ClientID = parentPck.Element.ElementID
										parentCon.SupplierID = depPck.Element.ElementID								
									else
										parentCon.SupplierID = parentPck.Element.ElementID
										parentCon.ClientID = depPck.Element.ElementID																
									end if
									if con.Notes = "Calculated" then parentCon.Notes = "Calculated"
									parentCon.Update
									parentPck.Connectors.Refresh
								end if
							end if
						else
							Repository.WriteOutput "Special", Now & " Depending package not in level 2 list: " & tmpPck.Name, 0
						end if	
					end if
				end if						
			end if
		next
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
	
	'Create list with each package's level in the model
	For each thePackage in theModel.Packages
		'set thePackage = Repository.GetTreeSelectedPackage()
		recPackageLevelList thePackage, 0
	next
	
	'Aggregate dependencies in the package "ISO TC 211" to level 2
	set thePackage = theModel.Packages.GetByName("ISO TC211")
	level2Dependencies

	Repository.WriteOutput "Script", Now & " " ,0
	Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
	Repository.EnsureOutputVisible "Script"
end sub

MainPackageDependencies
