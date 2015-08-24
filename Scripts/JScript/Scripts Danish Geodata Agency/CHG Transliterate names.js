!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-TaggedValue
!INC EAScriptLib.JScript-Logging
!INC _TaggedValuesHelperFunctions
!INC _VersionControlHelperFunctions
!INC _ModelHelperFunctions

var TAG_NAME_TRANSLITERATED_NAME = "transliteratedName";

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;
 
 
/**
 * Purpose: Transliterate the danish characters to latin characters (but not on enumeration values)
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
		var currentElement as EA.Element;
		var elements = getElementsOfPackageAndSubpackages(thePackage);
		for (var i = 0; i < elements.length; i++) {
			currentElement = elements[i];
			if (currentElement.Type == "Class" || currentElement.Type == "DataType") {
				transliterateNameAndUpdateTaggedValueElement(currentElement);
				
				var attributes as EA.Collection;
				attributes = currentElement.Attributes;
				for (var j = 0; j < attributes.Count; j++) {
					var currentAttribute as EA.Attribute;
					currentAttribute = attributes.GetAt(j);
					transliterateNameAndUpdateTaggedValueAttribute(currentAttribute);
				}		

				var connectors as EA.Collection;
				connectors = currentElement.Connectors;
				for (var j = 0; j < connectors.Count; j++) {
					var currentConnector as EA.Connector;
					currentConnector = connectors.GetAt(j);
					var proceed = isConnectorAssociationAndControlledInSamePackageAsElement(currentConnector, currentElement);
					if (proceed) {
						transliterateNameAndUpdateTaggedValueConnectorEnd(currentConnector, true);
						transliterateNameAndUpdateTaggedValueConnectorEnd(currentConnector, false);
					}
				}
			} else if (currentElement.Type == "Enumeration") {
				transliterateNameAndUpdateTaggedValueElement(currentElement);
				/*
				* next lines of code: update models that actually contain transliterated names for enumeration values, from earlier modelling
				*/
				var attributes as EA.Collection;
				attributes = currentElement.Attributes;
				for (var j = 0; j < attributes.Count; j++) {
					removeTaggedValueIfPresent(attributes.GetAt(j));
				}
			}
		}		
		LOGInfo( "Done!" );
	}
	else
	{
		Session.Prompt( "This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK );
	}
}

function transliterateNameAndUpdateTaggedValueElement(element) {
	LOGDebug("Element: " + element.Name);
	if (mustBeTransliterated(element.Name)) {
		var transliteratedName = transliterate(element.Name);
		setTaggedValueElement(element, TAG_NAME_TRANSLITERATED_NAME, transliteratedName);
		LOGInfo("Transliterated name: " + transliteratedName + " of element " + element.Name);
	} else {
		removeTaggedValueIfPresent(element);
	}
}

function transliterateNameAndUpdateTaggedValueAttribute(attribute) {
	LOGDebug("Attribute: " + attribute.Name);
	if (mustBeTransliterated(attribute.Name)) {
		var transliteratedName = transliterate(attribute.Name);
		setTaggedValueAttribute(attribute, TAG_NAME_TRANSLITERATED_NAME, transliteratedName);
		LOGInfo("Transliterated name: " + transliteratedName + " of attribute " + attribute.Name);
	} else {
		removeTaggedValueIfPresent(attribute);
	}
}

function transliterateNameAndUpdateTaggedValueConnectorEnd(connector, source) {
	var roleName = null;
	if (source) {
		roleName = connector.ClientEnd.Role;
	} else {
		roleName = connector.SupplierEnd.Role;
	}
	LOGDebug("Connector end role: " + roleName);
	if (mustBeTransliterated(roleName)) {
		var transliteratedName = transliterate(roleName);
		setTaggedValueConnectorEnd(connector, TAG_NAME_TRANSLITERATED_NAME, transliteratedName, source);
		LOGInfo("Transliterated name: " + transliteratedName + " of connector end " + roleName);
	} else {
		removeTaggedValueConnectorEndIfPresent(connector, source);
	}
}

function mustBeTransliterated(name) {
	return name.search(/æ|ø|å/i) != -1;
}

function transliterate(name) {
	return name.replace(/æ/g, "ae").replace(/Æ/g, "Ae").replace(/ø/g, "oe").replace(/Ø/g, "Oe").replace(/å/g, "aa").replace(/Å/g, "Aa");
}

function removeTaggedValueIfPresent(object /* element or attribute */) {
	for (var i = 0; i < object.TaggedValues.Count; i++) {
		var tag = object.TaggedValues.GetAt(i);
		if (tag.Name == TAG_NAME_TRANSLITERATED_NAME) {
			object.TaggedValues.DeleteAt(i, true);
		}
	}	
	object.TaggedValues.Refresh();
}

function removeTaggedValueConnectorEndIfPresent(connector, source /* boolean, false => target */) {
	var taggedValues as EA.Collection;
	if (source) {
		taggedValues = connector.ClientEnd.TaggedValues;
	} else {
		taggedValues = connector.SupplierEnd.TaggedValues;
	}
	for (var i = 0; i < taggedValues.Count; i++) {
		var tag = taggedValues.GetAt(i);
		if (tag.Tag == TAG_NAME_TRANSLITERATED_NAME) {
			taggedValues.DeleteAt(i, true);
		}
	}
	taggedValues.Refresh();
}

main();