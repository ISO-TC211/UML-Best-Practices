!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging 
!INC EAScriptLib.JScript-String
!INC _TaggedValuesHelperFunctions
!INC _VersionControlHelperFunctions
 
var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

/*
* Moves the documentation from the Notes-field (where delimiters -- Definition -- and -- Description -- are used) to tagged values, as required
* in "modelregler 1.1".
*/
function main() {
	// Show the script output window
	Repository.EnsureOutputVisible("Script");
	
	LOGInfo("=======================================");

	// Get the currently selected package in the tree to work on
	var toplevelPackage as EA.Package;
	toplevelPackage = Repository.GetTreeSelectedPackage();
	
	if (toplevelPackage != null && toplevelPackage.ParentID != 0)	{
		LOGInfo("Working on package '" + toplevelPackage.Name + "' (ID=" + toplevelPackage.PackageID + ")" );
		updatePackageAndContents(toplevelPackage);
		var aPackage as EA.Package;
		for (var i = 0; i < toplevelPackage.Packages.Count; i++) {
			aPackage = toplevelPackage.Packages.GetAt(i);
			updatePackageAndContents(aPackage);
		}
		LOGInfo("Done!");
	}
	else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

function updatePackageAndContents(aPackage) {
	for (var i = 0; i < aPackage.Elements.Count; i++) {
		var anElement as EA.Element;
		anElement = aPackage.Elements.GetAt(i);
		if (anElement.Stereotype.substr(0, 2) == "DK") {
			/* Elements */
			LOGDebug("Notes on " + anElement.name + ":\r\n" + anElement.Notes);
			var array = arrayDefinitionDescription(anElement.Notes);
			LOGDebug("Definition: " + array[0]);
			LOGDebug("Description: " + array[1]);
			setTaggedValueElement(anElement, "definition", array[0]);
			setTaggedValueElement(anElement, "note", array[1]);
			setTaggedValueElement(anElement, "eksempel", "");
			anElement.Notes = "";
			anElement.Update();
			
			for (var j = 0; j < anElement.Attributes.Count; j++) {
				var anAttribute as EA.Attribute;
				anAttribute = anElement.Attributes.GetAt(j);
				var array2 = arrayDefinitionDescription(anAttribute.Notes);
				setTaggedValueAttribute(anAttribute , "definition", array2[0]);
				setTaggedValueAttribute(anAttribute , "note", array2[1]);
				setTaggedValueAttribute(anAttribute , "eksempel", "");
				anAttribute.Notes = "";
				anAttribute.Update();
			}
			
			for (var k = 0; k < anElement.Connectors.Count; k++) {
				var aConnector as EA.Connector;
				aConnector = anElement.Connectors.GetAt(k);
				var proceed = isConnectorAssociationAndControlledInSamePackageAsElement(aConnector, anElement);
				if (proceed) {
					LOGDebug("Proceed with connector " + aConnector.Name + " (GUID=" + aConnector.ConnectorGUID +  ")");
					var array3 = arrayDefinitionDescription(aConnector.ClientEnd.RoleNote);
					/* The following 2 lines make the contents of the tagged values disappear,
					even when they are set after those lines. Very strange... Role Notes
					have to be updated manually. */
					//aConnector.ClientEnd.RoleNote = "";
					//aConnector.ClientEnd.Update();
					setTaggedValueConnectorEnd(aConnector, "definition", array3[0], true);
					setTaggedValueConnectorEnd(aConnector, "note", array3[1], true);
					setTaggedValueConnectorEnd(aConnector, "eksempel", "", true);
					var array4 = arrayDefinitionDescription(aConnector.SupplierEnd.RoleNote);
					/* The following 2 lines make the contents of the tagged values disappear,
					even when they are set after those lines. Very strange... Role Notes
					have to be updated manually. */
					//aConnector.SupplierEnd.RoleNote = "";
					//aConnector.SupplierEnd.Update();
					setTaggedValueConnectorEnd(aConnector, "definition", array4[0], false);
					setTaggedValueConnectorEnd(aConnector, "note", array4[1], false);
					setTaggedValueConnectorEnd(aConnector, "eksempel", "", false);
				} else {
					LOGInfo("Documentation on connector " + aConnector.Name + " is not updated because it is not an association and/or controlled in another package");
				}
			}
		}
	}
}

function arrayDefinitionDescription(notes /* : String */) /* : array of 2 Strings */ {
	var split1 = notes.split("-- Definition --\r\n");
	var definition;
	var description;
	if (split1.length == 2) {
		var split2 = split1[1].split("-- Description --\r\n");
		if (split2.length == 1) {
			description = '';
		} else if (split2.length == 2) {
			description = STRTrim(split2[1]);
		} else {
			LOGError("Unexpected length " + split2.length + " on the following notes:\r\n" + notes);
		}
		if (STRTrim(split2[0]).length <= 255) {
			definition = STRTrim(split2[0]);
		} else {
			definition = STRTrim(split2[0]).substr(0, 255);
		}
	} else { // ingen definition
		definition = '';
		var split3 = notes.split("-- Description --\r\n");
		if (split3.length == 2) {
			description = STRTrim(split3[1]);
		} else {
			description = '';
		}
	}
	
	return new Array(definition, description);
}

main();