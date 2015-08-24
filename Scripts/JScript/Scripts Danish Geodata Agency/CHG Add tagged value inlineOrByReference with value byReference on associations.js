!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _TaggedValuesHelperFunctions

/*
 * Purpose: sets tagged value inlineOrByReference.
 * NOTE: this scripts assumes that the Direction on the connector is Source -> Destination
 */
 
var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;
 
 var TAG_NAME = "inlineOrByReference";
 var TAG_VALUE = "byReference";
 
function main() {
	// Show the script output window
	Repository.EnsureOutputVisible("Script");

	// Get the currently selected package in the tree to work on
	var thePackage as EA.Package;
	thePackage = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	LOGInfo("Working on package '" + thePackage.Name + "' (ID=" + thePackage.PackageID + ")" );
	
	if (thePackage != null && thePackage.ParentID != 0) {
		var elements as EA.Collection;
		elements = thePackage.Elements;
		for (var i = 0; i < elements.Count; i++) {
			var currentElement as EA.Element;
			currentElement = elements.GetAt(i);
			if (currentElement.Type == "Class") {
				var connectors as EA.Collection;
				connectors = currentElement.Connectors;
				for (var j = 0; j < connectors.Count; j++) {
					var currentConnector as EA.Connector;
					currentConnector = connectors.GetAt(j);
					if (currentConnector.ClientID == currentElement.ElementID && currentConnector.Type == "Association" 
						&& currentConnector.Direction == "Source -> Destination") {
						setTaggedValueConnectorEnd(currentConnector, TAG_NAME, TAG_VALUE, false);
						LOGDebug("Set tagged value inlineOrByReference to byReference on connector of element " + currentElement.Name);
					}
				}
			}
		}
		
		thePackage.Elements.Refresh();
		
		LOGInfo( "Done!" );
	}
	else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

main();