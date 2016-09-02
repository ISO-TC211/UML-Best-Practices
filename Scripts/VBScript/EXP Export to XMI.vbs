option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Export to XMI
' Author: Knut Jetlund
' Purpose: Export to XMI - loops trough a selected package and subpackages, and export to XMI files
' Date: 20160616
'
const path="C:\DATA\GitHub\HMMG\XMI\2.1\Conceptual\"

sub recExport(p)
	if p.IsVersionControlled then
		Repository.WriteOutput "Script", Now & " Exporting package: " & p.Name, 0
		'
		'http://www.sparxsystems.com/enterprise_architect_user_guide/12.1/automation_and_scripting/project_2.html
		'http://sparxsystems.com/forums/smf/index.php/topic,5639.msg125930.html#msg125930
		dim pI as EA.Project
		set pI = Repository.GetProjectInterface()
		dim XmiExportType
		'XmiExportType = 18 ' this value is for xmiEA242
		XmiExportType = 11 ' this value is for xmiEA21
		dim result
		dim fName 
		fName = Replace(p.Name,":","_")
		fName = Replace(fName,"/","")
		Repository.WriteOutput "Script", Now & " Filename: " &  fName, 0
		
		result = pI.ExportPackageXMI(p.PackageGUID, XmiExportType, 1, -1, 1, 0, path & fName & ".xmi")
		Repository.EnsureOutputVisible "Script"
	else
		Repository.WriteOutput "Script", Now & " Uncontrolled package: " & p.Name, 0
	end if	
	
	dim subP as EA.Package
	for each subP in p.packages
	    recExport(subP)
	next
end sub

sub main
	' Show and clear the script output window
	Repository.ClearOutput "Script"
	Repository.EnsureOutputVisible "Script"
	'Repository.CreateOutputTab "Error"
	'Repository.ClearOutput "Error"
	Repository.ClearOutput "Version Control"		
	
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
	if not thePackage is nothing then
		recExport(thePackage)
		Repository.WriteOutput "Script", Now & " Finished", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main