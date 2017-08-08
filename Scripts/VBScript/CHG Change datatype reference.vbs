option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: Add package tags 
' Author: Knut Jetlund
' Purpose: Change attribute datatype references, i.e. for updating from 19103:2005 to 19103:2015
' Date: 20170803
'
' NOTE: Requires a package to be selected in the Project Browser
' 
'CharacterString
const fromDT=151
const toDT=534

'Integer
'const fromDT=148
'const toDT=534


'Recursive loop through subpackages, and do the thing
sub recPros(p)
	Repository.WriteOutput "Script", Now & " Package: " & p.Name, 0
	dim el as EA.Element
	dim attr as EA.Attribute
	for each el in p.Elements
		Repository.WriteOutput "Script", Now & " Element: " & p.Name & "." & el.Name, 0
		for each attr in el.Attributes
		   if attr.ClassifierID= fromDT then
				Repository.WriteOutput "Script", Now & " Attribute change: " & p.Name & "." & el.Name & "." & attr.Name, 0
				attr.ClassifierID=toDT
				attr.Update
		   end if
		next
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
