!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _ModelHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

/**
 * @author Geodatastyrelsen 
 */
function main() {
	// Show the script output window
	Repository.EnsureOutputVisible("Script");
	
	LOGInfo("=======================================");	
	
	// Get the currently selected package in the tree to work on
	var aPackage as EA.Package;
	aPackage = Repository.GetTreeSelectedPackage();
	
	if (aPackage != null && aPackage.ParentID != 0)	{
		LOGInfo("Working on package '" + aPackage.Name + "' (ID=" + aPackage.PackageID + ")" );
		var diagrams = getDiagramsOfPackageAndSubpackages(aPackage);
		var diagram as EA.Diagram;
		for (var i = 0; i < diagrams.length; i++) {
			diagram = diagrams[i];
			diagram.Scale = 100;
			diagram.Update();
		}
		LOGInfo("Done!");
	}
	else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

main();