option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: Change data type references
' Author: Knut Jetlund
' Purpose: change data type reference for selected data types
' Date: 20160623
'
' NOTE: Requires a package to be selected in the Project Browser

'Const oldClID = 129221
'ConSt newClID = 115143

Const oldClID = 129219
ConSt newClID = 115142


'Recursive loop through subpackages and their elements, with controll of attributes
sub recChangeClassifier(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	for each el In p.elements
		if el.Stereotype = "featureType" or el.Stereotype = "FeatureType" then
			Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & el.Name, 0
			dim attr as EA.Attribute
			for each attr in el.Attributes
				if attr.ClassifierID = oldClID then
					attr.ClassifierID = newClID
					attr.Update
					Repository.WriteOutput "Types", p.Name & "." & el.Name & "." & attr.Name & " (Data type classifier ID changed from: " & oldClID & " to " & attr.ClassifierID  & ")",0
				end if	
			next
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recChangeClassifier(subP)
	next
end sub

sub main()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Types"
	Repository.ClearOutput "Types"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recChangeClassifier(thePackage)
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Types tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main
