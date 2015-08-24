!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _ModelHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;
 
 /**
 * Purpose: change types to types found in the model.
 *
 * @author Geodatastyrelsen
 */
function main() {
	// Show the script output window
	Repository.EnsureOutputVisible("Script");

	// Get the currently selected package in the tree to work on
	var thePackage as EA.Package;
	thePackage = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	LOGInfo("Working on package '" + thePackage.Name + "' (ID=" + thePackage.PackageID + ")" );
	
	if (thePackage != null && thePackage.ParentID != 0) {
		var elements = getElementsOfPackageAndSubpackages(thePackage);
		for (var i = 0; i < elements.length; i++) {
			var currentElement as EA.Element;
			currentElement = elements[i];
			
			if (currentElement.Type == "Class" || currentElement.Type == "DataType") {
				LOGDebug("Working on " + currentElement.Name);
				var attributes as EA.Collection;
				attributes = currentElement.Attributes;
					
				for (var j = 0; j < attributes.Count; j++) {
					var currentAttribute as EA.Attribute;
					currentAttribute = attributes.GetAt(j);
					LOGDebug("Attribute " + currentAttribute.Name + " with classifierId " + currentAttribute.ClassifierID + " and type " + currentAttribute.Type);
					if (currentAttribute.ClassifierID == 0) {
						var foundElements as EA.Collection;
						foundElements = Repository.GetElementSet("SELECT * FROM t_object WHERE Name = '" + currentAttribute.Type + "'", 2);
						LOGDebug("Count: " + foundElements.Count);
						if (foundElements.Count == 0) {
							LOGError("Not found: " + currentAttribute.Type);
						} else if (foundElements.Count == 1) {
							LOGDebug("Found: " + foundElements.GetAt(0).Name);
							currentAttribute.ClassifierID = foundElements.GetAt(0).ElementID;
							currentAttribute.Update();
						} else if (currentAttribute.Type == 'Boolean') {
							// 19103:2015 contains two model constructs with name Boolean, choose the right one:
							var correctCharacterStringElement = Repository.GetElementByGuid("{8887B7F7-C12C-4c24-99B4-BCA7B303291F}");
							LOGDebug("Picking CharacterString with GUID {8887B7F7-C12C-4c24-99B4-BCA7B303291F} from ISO 19103:2015");
							currentAttribute.ClassifierID = correctCharacterStringElement.ElementID;
							currentAttribute.Update();
						} else if (currentAttribute.Type == 'CharacterString') {
							// 19103:2015 contains two model constructs with name CharacterString, choose the right one:
							var correctCharacterStringElement = Repository.GetElementByGuid("{0A614EA9-13B7-4ebe-85ED-AA187D27CBD1}");
							LOGDebug("Picking CharacterString with GUID {0A614EA9-13B7-4ebe-85ED-AA187D27CBD1} from ISO 19103:2015");
							currentAttribute.ClassifierID = correctCharacterStringElement.ElementID;
							currentAttribute.Update();
						} else if (currentAttribute.Type == 'GM_Point') {
							// 19103:2015 contains two model constructs with name GM_Point, choose the one from ISO 19107!:
							var correctCharacterStringElement = Repository.GetElementByGuid("{3CC5A3E8-2ECA-4e42-B09C-935BD5D3B64A}");
							LOGDebug("Picking CharacterString with GUID {3CC5A3E8-2ECA-4e42-B09C-935BD5D3B64A} from ISO 19107:2003");
							currentAttribute.ClassifierID = correctCharacterStringElement.ElementID;
							currentAttribute.Update();
						} else if (currentAttribute.Type == 'UomWeight') {
							// 19103:2015 contains two model constructs with name UomWeight, choose the right one:
							var correctCharacterStringElement = Repository.GetElementByGuid("{22EB37C8-C673-4636-ACFC-6FAF355A619D}");
							LOGDebug("Picking CharacterString with GUID {22EB37C8-C673-4636-ACFC-6FAF355A619D} from ISO 19103:2015");
							currentAttribute.ClassifierID = correctCharacterStringElement.ElementID;
							currentAttribute.Update();
						} else {
							LOGError("More than one " + currentAttribute.Type + " found in model, update the attributes with that type manually (access them via model search val_attribute_type)");
						}
					}
				}
				currentElement.Update();
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