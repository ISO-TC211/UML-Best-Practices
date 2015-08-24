!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _ModelHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

/**
* Sets the visibility of all attributes in the given package and its subpackages to Public.
* 
* The default visibility when adding a new atribute in EA via the user interface is Private. When using EA
* mainly for data modelling, all attributes should be public. This scripts saves the clicks it takes to set 
* the visibility of every attribute manually to Public.
*
* See also http://stackoverflow.com/questions/16987496/how-to-change-the-default-scope-of-attributes-from-private-to-public-in-enterpri
* 
* @author Geodatastyrelsen
*/
function main() {
	// Show the script output window
    Repository.EnsureOutputVisible("Script");

    // Get the currently selected package in the tree to work on
	var aPackage as EA.Package;
	aPackage = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	LOGInfo("Working on package '" + aPackage.Name + "' (ID=" + aPackage.PackageID + ")" );
	
	if (aPackage != null && aPackage.ParentID != 0)	{
		var element as EA.Element;
		var attribute as EA.Attribute;
		var elements = getElementsOfPackageAndSubpackages(aPackage);
	
		for (var i = 0; i < elements.length; i++) {
			element = elements[i];
			for (var j = 0; j < element.Attributes.Count; j++) {
				attribute = element.Attributes.GetAt(j);
				if (attribute.Visibility != "Public") {
					attribute.Visibility = "Public";
					attribute.Update();
					LOGDebug("Changed visibility of attribute " + attribute.Name);
				}
			}
		}
		LOGInfo("Done!");
	} else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

main();