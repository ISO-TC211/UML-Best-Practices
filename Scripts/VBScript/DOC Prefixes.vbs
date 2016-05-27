option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: List prefixes
' Author: Knut Jetlund
' Purpose: List all prefixes (characters before the first "_" in a element name)
' Date: 20150422
'
' NOTE: Requires a package to be selected in the Project Browser

'Recursive loop through subpackages and their elements, with controll of prefixes
sub recListPrefixes(p,strP, apfx)
	Repository.WriteOutput "Script", Now & " Package: " & strP, 0
	dim el as EA.Element
	for each el In p.elements
		Repository.WriteOutput "Script", Now & " " & el.Stereotype & " " & strP & "." & el.Name, 0
		dim pstn
		pstn=InStr (el.name,"_")
		if pstn > 0 then 
			dim pfx
			pfx = left(el.name,pstn-1) & "#" & strP 
		    'Repository.WriteOutput "Prefix", Now & " Element with prefix: " & el.Name, 0
		    apfx.Add pfx
		end if
	next
	
	dim subP as EA.Package
	for each subP in p.packages
	    recListPrefixes subP,strP & "." & subP.Name, apfx
	next
end sub

sub listPrefixes()
	' Show and clear the script output window
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Prefix"
	Repository.ClearOutput "Prefix"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
		
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
	
	dim lstPfx
	Set lstPfx = CreateObject("System.Collections.ArrayList") 
	if not thePackage is nothing and thePackage.ParentID <> 0 then
		recListPrefixes thePackage,thePackage.Name, lstPfx
		
		Repository.WriteOutput "Script", Now & " Elements with prefix: " & lstPfx.Count, 0 
		
		'create dictionary with unique keys
		dim d
		Set d = CreateObject("Scripting.Dictionary")
		dim i
		for i = 0 To lstPfx.Count - 1
			d(lstPfx.item(i)) = d(lstPfx.item(i)) + 1
		next
		
		Repository.WriteOutput "Script", Now & " Unique prefix-package combinations: " & d.Count, 0 

		
		'create new empty list
		Set lstPfx = CreateObject("System.Collections.Sortedlist")  '("Scripting.Dictionary") '
		'create arry with the unique keys
		'dim a
		'a = d.Keys   ' Get the keys into an array.
		'For i = 0 To d.Count -1 ' Iterate the array and create sorted list of prefixes.
		dim str
		for each str in d.Keys()
			dim pfx, pck
			'str=a(i)
			pfx=left(str, instr(str,"#")-1)
			pck=mid(str,instr(str,"#")+1)
			lstPfx.Add pfx & " # " & pck, pfx & " # " & pck & " # " & d.Item(str)
		Next
		
		for i = 0 to lstPfx.count - 1
		  Repository.WriteOutput "Prefix", lstPfx.GetByIndex(i), 0' Return results.
		Next
		
		Repository.WriteOutput "Script", Now & " Finished, check the Error and Prefix tabs", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

listPrefixes
