!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _ModelHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

/**
 * Sets the language of all class, datatypes, enumerations and packages in the selected package to <none>.
 * 
 * @author Geodatastyrelsen
 */
function main() {
	Repository.EnsureOutputVisible("Script");

	var package as EA.Package;
	package = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	if (package != null && package.ParentID != 0) {
		LOGInfo("Working on package '" + package.Name + "' (ID=" + package.PackageID + ").");
		var language = "<none>";
		var elements = getElementsOfPackageAndSubpackages(package);
		for (var i in elements) {
			var element as EA.Element;
			element = elements[i];
			if (element.Type == "Class" || element.Type == "Enumeration" || element.Type == "DataType") {
				element.Gentype = language;
				element.Update();
				LOGDebug("Set language to " + language + " on " + element.Name);
			}
		}
		var packages = getSubpackagesOfPackage(package);
		packages = packages.concat(package);
		for (var i in packages) {
			var package as EA.Package;
			var element as EA.Element;
			package = packages[i];
			element = package.Element;
			element.Gentype = language;
			element.Update();
			LOGDebug("Set language to " + language + " on " + package.Name);
		}
		LOGInfo("Done.")
	} else {
		Session.Prompt( "This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK );
	}
}

main();