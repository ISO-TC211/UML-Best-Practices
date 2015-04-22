option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Count subpackages
' Author: Knut Jetlund
' Purpose: Count first level subpackages in the selected package
' Date: 20150313
'
'
' NOTE: Requires a package to be selected in the Project Browser
' 
' Related APIs
' =================================================================================
' Element API - http://www.sparxsystems.com/uml_tool_guide/index.html?element2.htm
'
sub CountSP()

	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script" 
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
		
	dim i 
	i=0
	
	dim p as EA.Package
	
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		for each p in thePackage.packages
		  Session.Output(p.name & " (" & i & ")")
		  i=i+1
		next
		
		Session.Output( "Number of first level subpackages: " & i)
		
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if


end sub

CountSP
