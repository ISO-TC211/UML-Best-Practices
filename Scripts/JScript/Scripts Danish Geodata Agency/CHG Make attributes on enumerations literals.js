!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

var IS_LITERAL_PREFIX = "IsLiteral=";
var IS_NOT_LITERAL_STRING = IS_LITERAL_PREFIX + "0";

/**
 * Purpose: All attributes on enumerations (this is, object type enumeration, can be any stereotype) should have checkbox "Is Literal" checked.
 * 
 * @author Geodatastyrelsen
 */
function main()
{
		// Show the script output window
	Repository.EnsureOutputVisible( "Script" );

	// Get the currently selected package in the tree to work on
	var thePackage as EA.Package;
	thePackage = Repository.GetTreeSelectedPackage();
	
	LOGInfo( "=======================================" );
	
	if ( thePackage != null && thePackage.ParentID != 0 ) {
		LOGInfo("Working on package '" + thePackage.Name + "' (ID=" + thePackage.PackageID + ")" );
				
		var elements as EA.Collection;
		elements = thePackage.Elements;
		
		for (var i = 0 ; i < elements.Count ; i++)
		{
			var currentElement as EA.Element;
			currentElement = elements.GetAt(i);
			
			LOGDebug("Element: " + currentElement.Name);
			if (currentElement.Type == "Enumeration") {
				LOGDebug("Enumeration");
				
				var attributes as EA.Collection;
				attributes = currentElement.Attributes;
				
				for (var j = 0; j < attributes.Count; j++) {
					var currentAttribute as EA.Attribute;
					currentAttribute = attributes.GetAt(j);
					if (currentAttribute.StyleEx.indexOf(IS_NOT_LITERAL_STRING) != -1
						|| currentAttribute.StyleEx.indexOf(IS_LITERAL_PREFIX) == -1) {
						currentAttribute.StyleEx = "IsLiteral=1;volatile=0;";
						currentAttribute.Update();
						LOGDebug("Updated " + currentAttribute.Name);
					}
				}
			}
		}
		
		thePackage.Elements.Refresh();
		
		LOGInfo("Done!");
	}
	else
	{
		Session.Prompt( "This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK );
	}
}

main();