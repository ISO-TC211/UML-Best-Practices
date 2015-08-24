!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC EAScriptLib.JScript-Dialog
!INC _TaggedValuesHelperFunctions
!INC _CSVHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

var CSV_DELIMITER = ",";

/* No quotes in the fields, as opposed to in the export script, because they are stripped when parsed. */
var HEADER_FIELD_GUID = 'GUID';
var HEADER_FIELD_ELEMENT = 'Element';
var HEADER_FIELD_ATTRIBUTE = 'Attribut';
var HEADER_FIELD_CONNECTOR = 'Relation';
var HEADER_FIELD_CONNECTOR_END = 'Rolle';
var HEADER_FIELD_DEFINITION = 'Definition';
var HEADER_FIELD_NOTE = 'Note';
var HEADER_FIELD_EKSEMPEL = 'Eksempel';
var HEADER_FIELD_LOVGRUNDLAG = 'Lovgrundlag';
var HEADER_FIELD_ALTERNATIVT_NAVN = 'Alternativt navn';

/**
 * Imports the tagged values definition, scope, lovgrundlag, eksempel and alternativtNavn on elements, attributes,
 * enumeration values and relation ends from CSV files, encoded in UTF-8.
 *
 * Remember to check the system output for any warnings, since some tagged values are restricted in size and contents in EA.
 *
 * @author Geodatastyrelsen
 */
function main() {
	Repository.EnsureOutputVisible("Script");
	
	var package as EA.Package;
	package = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");	
	
	if (package != null && package.ParentID != 0) {
		LOGInfo("Working on package '" + package.Name + "' (ID=" + package.PackageID + ")" );
		var fileName = openCSVFileDialog();
		if (!(fileName == null || fileName == "")) {
			var parsedContents = parseCSVFile(fileName);
			var header = parsedContents[0];
			var columnMap = createColumnMap(header);
			var processed = false;
			
			var continueWithElements = columnMapDescribesElements(columnMap);
			if (continueWithElements) {
				processed = true;
				importDocumentationElements(parsedContents, columnMap, package);
			}
			
			// attributes and enumeration values
			var continueWithAttributes = columnMapDescribesAttributes(columnMap);
			if (continueWithAttributes) {
				processed = true;
				importDocumentationAttributes(parsedContents, columnMap, package);
			}
			
			var continueWithConnectorEnds = columnMapDescribesConnectorEnds(columnMap);
			if (continueWithConnectorEnds) {
				processed = true;
				importDocumentationConnectorEnds(parsedContents, columnMap);
			}
			
			if (processed) {
				LOGInfo("Done.");
			} else {
				LOGWarning("Header not recognized, double-check the contents of your CSV file.");
			}
			
			
		} else {
			Session.Prompt("No file was specified", promptOK);
		}
	}
	else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

function createColumnMap(header /* 1-dim array */) { /* Scripting.Dictionary */
	var columnMap = new ActiveXObject("Scripting.Dictionary");
	for (var i = 0; i < header.length; i++) {
		columnMap.Add(header[i], i);
	}
	return columnMap;
}

function columnMapDescribesElements(columnMap /* Scripting.Dictionary */) { /* boolean */
	return (
	!columnMap.Exists(HEADER_FIELD_ATTRIBUTE)
	&& !columnMap.Exists(HEADER_FIELD_CONNECTOR)
	&& columnMap.Exists(HEADER_FIELD_ELEMENT)
	&& columnMap.Exists(HEADER_FIELD_DEFINITION)
	&& columnMap.Exists(HEADER_FIELD_NOTE)
	&& columnMap.Exists(HEADER_FIELD_EKSEMPEL)
	&& columnMap.Exists(HEADER_FIELD_LOVGRUNDLAG)
	);
}

/**
 * Attributes and enumerations literals.
 */
function columnMapDescribesAttributes(columnMap /* Scripting.Dictionary */) { /* boolean */
	return (
	columnMap.Exists(HEADER_FIELD_ELEMENT)
	&& columnMap.Exists(HEADER_FIELD_ATTRIBUTE)
	&& columnMap.Exists(HEADER_FIELD_DEFINITION)
	&& columnMap.Exists(HEADER_FIELD_NOTE)
	&& columnMap.Exists(HEADER_FIELD_EKSEMPEL)
	&& columnMap.Exists(HEADER_FIELD_LOVGRUNDLAG)
	);
}

function columnMapDescribesConnectorEnds(columnMap /* Scripting.Dictionary */) { /* boolean */
	return (
	columnMap.Exists(HEADER_FIELD_GUID)
	&& columnMap.Exists(HEADER_FIELD_CONNECTOR)
	&& columnMap.Exists(HEADER_FIELD_CONNECTOR_END)
	&& columnMap.Exists(HEADER_FIELD_DEFINITION)
	&& columnMap.Exists(HEADER_FIELD_NOTE)
	&& columnMap.Exists(HEADER_FIELD_EKSEMPEL)
	&& columnMap.Exists(HEADER_FIELD_LOVGRUNDLAG)
	);
}

function importDocumentationElements(parsedContents, columnMap, package) {
	var element as EA.Element;
	for (var i = 1; i < parsedContents.length; i++) {
		var row = parsedContents[i];
		if (columnMap.Exists(HEADER_FIELD_GUID)) {
			var guid = row[columnMap.Item(HEADER_FIELD_GUID)];
			LOGInfo("Handling element with guid " + guid);
			element = Repository.GetElementByGuid(guid);
		} else { /* old code: to import csv files without GUID's (only packages without subpackages) */
			var name = row[columnMap.Item(HEADER_FIELD_ELEMENT)];
			LOGInfo("Handling element with name " + name);
			element = package.Elements.GetByName(name);
		}
		if (element == null) {
			LOGWarning("Element not found");
		} else {
			setTaggedValueElement(element, "definition", row[columnMap.Item(HEADER_FIELD_DEFINITION)]);
			setTaggedValueElement(element, "note", row[columnMap.Item(HEADER_FIELD_NOTE)]);
			setTaggedValueElement(element, "eksempel", row[columnMap.Item(HEADER_FIELD_EKSEMPEL)]);
			setTaggedValueElement(element, "lovgrundlag", row[columnMap.Item(HEADER_FIELD_LOVGRUNDLAG)]);
			if (columnMap.Exists(HEADER_FIELD_ALTERNATIVT_NAVN)) {
				setTaggedValueElement(element, "alternativtNavn", row[columnMap.Item(HEADER_FIELD_ALTERNATIVT_NAVN)]);
			}
		}
	}
}

function importDocumentationAttributes(parsedContents, columnMap, package) {
	var element as EA.Element;
	var attribute as EA.Attribute;
	for (var i = 1; i < parsedContents.length; i++) {
		var row = parsedContents[i];
		if (columnMap.Exists(HEADER_FIELD_GUID)) {
			var guid = row[columnMap.Item(HEADER_FIELD_GUID)];
			LOGInfo("Handling attribute with guid " + guid);
			attribute = Repository.GetAttributeByGuid(guid);
		} else { /* old code: to import csv files without GUID's (only packages without subpackages) */
			var elementName = row[columnMap.Item(HEADER_FIELD_ELEMENT)];
			var attributeName = row[columnMap.Item(HEADER_FIELD_ATTRIBUTE)];
			LOGInfo("Handling attribute " + attributeName + " on element " + elementName);
			element = package.Elements.GetByName(elementName);
			if (element == null) {
				attribute = null;
				LOGWarning("Element not found");
			} else {
				// GetByName not supported for Collection of EA.Attribute
				var anAttribute as EA.Attribute;
				for (var j = 0; j < element.Attributes.Count; j++) {
					anAttribute = element.Attributes.GetAt(j)
					if (anAttribute.Name == attributeName) {
						attribute = anAttribute;
						break;
					}
				}
			}
		}
		if (attribute == null) {
			LOGWarning("Attribute not found");
		} else {
			setTaggedValueAttribute(attribute, "definition", row[columnMap.Item(HEADER_FIELD_DEFINITION)]);
			setTaggedValueAttribute(attribute, "note", row[columnMap.Item(HEADER_FIELD_NOTE)]);
			setTaggedValueAttribute(attribute, "eksempel", row[columnMap.Item(HEADER_FIELD_EKSEMPEL)]);
			setTaggedValueAttribute(attribute, "lovgrundlag", row[columnMap.Item(HEADER_FIELD_LOVGRUNDLAG)]);
			if (columnMap.Exists(HEADER_FIELD_ALTERNATIVT_NAVN)) {
				setTaggedValueAttribute(attribute, "alternativtNavn", row[columnMap.Item(HEADER_FIELD_ALTERNATIVT_NAVN)]);
			}
		}
	}
}

function importDocumentationConnectorEnds(parsedContents, columnMap) {
	var element as EA.Element;
	var connector as EA.Connector;
	for (var i = 1; i < parsedContents.length; i++) {
		var row = parsedContents[i];
		var guid = row[columnMap.Item(HEADER_FIELD_GUID)]; /* only GUID, no csv files created with connectors without GUIDs */
		LOGInfo("Handling connector with guid " + guid);
		connector = Repository.GetConnectorByGuid(guid);
		var role, sourceRole, targetRole, isSource;
		if (connector == null) {
			LOGWarning("Connector not found");
		} else {
			role = row[columnMap.Item(HEADER_FIELD_CONNECTOR_END)];
			sourceRole = connector.ClientEnd.Role;
			targetRole = connector.SupplierEnd.Role;
			if (role == sourceRole && role != targetRole) {
				isSource = true;
			} else if (role != sourceRole && role == targetRole) {
				isSource = false;
			} else if (role != sourceRole && role != targetRole) {
				LOGWarning("Unknown role " + role + " on connector with guid" + guid);
				continue;
			} else {
				LOGWarning("Role " + role + " on both source and target of connector with guid " + guid);
				continue;
			}
						
			setTaggedValueConnectorEnd(connector, "definition", row[columnMap.Item(HEADER_FIELD_DEFINITION)], isSource);
			setTaggedValueConnectorEnd(connector, "note", row[columnMap.Item(HEADER_FIELD_NOTE)], isSource);
			setTaggedValueConnectorEnd(connector, "eksempel", row[columnMap.Item(HEADER_FIELD_EKSEMPEL)], isSource);
			setTaggedValueConnectorEnd(connector, "lovgrundlag", row[columnMap.Item(HEADER_FIELD_LOVGRUNDLAG)], isSource);
			if (columnMap.Exists(HEADER_FIELD_ALTERNATIVT_NAVN)) {
				setTaggedValueConnectorEnd(connector, "alternativtNavn", row[columnMap.Item(HEADER_FIELD_ALTERNATIVT_NAVN)], isSource);
			} else {
				// set explicitly to empty on connector ends,
				// because else the value contains the description of the tag from the Grunddata UML profile
				setTaggedValueConnectorEnd(connector, "alternativtNavn", "", isSource);
			}
		}
	}
}

main();