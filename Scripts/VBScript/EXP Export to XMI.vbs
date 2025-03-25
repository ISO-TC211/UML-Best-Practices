option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: Export to XMI
' Author: Knut Jetlund
' Purpose: Export to XMI - loops trough a selected package and subpackages, and export to XMI files
' Date: 20220804

'
const path="C:\DATA\GitHub\ISO TC211\HMMG\XMI\ConceptualModels\"
const maxLevels = 1
'const XmiExportType = 18 ' this value is for xmiEA242
'const XmiExportType = 11 ' this value is for xmiEA21
const XmiExportType = 3 ' this value is for xmiEA11 (1.1)


sub recExport(p,lc)
	if lc > 0 and lc <= maxLevels then
		Repository.WriteOutput "Script", Now & " Package for export: (level = " & lc & "): " & p.Name, 0
		dim pI as EA.Project
		set pI = Repository.GetProjectInterface()

		dim result
		dim fName 
		fName = Replace(p.Name,":","_")
		fName = Replace(fName,"/","")
		fName = path & fName & ".xml"
		Repository.WriteOutput "Export", Now & " Exporting package to file: " &  fName, 0
		p.IsControlled = -1
		p.XMLPath = fName
		p.BatchSave = 1
		p.BatchLoad = 1
		p.Update
		
		'Repository.WriteOutput "Export", Now & " Control settings: Controlled? "  & p.IsControlled & " file: " &  fName & " Batch load: " & p.BatchLoad & " BatchSave: " & p.BatchSave, 0

		'result = pI.ExportPackageXMI(p.PackageGUID, XmiExportType, 1, -1, 1, 0, fName)
		Repository.EnsureOutputVisible "Script"
	end if	
	
	dim subP as EA.Package
	if lc < maxLevels then
		for each subP in p.packages
			recExport subP,lc+1
		next
	end if	
end sub

sub main
	' Show and clear the script output window
	Repository.ClearOutput "Script"
	Repository.EnsureOutputVisible "Script"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
	Repository.CreateOutputTab "Export"
	Repository.ClearOutput "Export"
	
	' Get the currently selected package in the tree to work on
	dim thePackage as EA.Package
	set thePackage = Repository.GetTreeSelectedPackage()
	if not thePackage is nothing then
		Repository.WriteOutput "Script", Now & " Main package (level 0) : " & thePackage.Name, 0
		recExport thePackage,0
		Repository.WriteOutput "Script", Now & " Finished", 0 
		Repository.EnsureOutputVisible "Script"
	else
		' No package selected in the tree
		MsgBox( "This script requires a package to be selected in the Project Browser." & vbCrLf & _
			"Please select a package in the Project Browser and try again." )
	end if
end sub

main