!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-CSV
!INC EAScriptLib.JScript-Logging
!INC EAScriptLib.JScript-Dialog
!INC _TaggedValuesHelperFunctions
!INC _CSVHelperFunctions
!INC _ModelHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

var CSV_DELIMITER = ",";

var HEADER_FIELD_GUID = '"GUID"';
var HEADER_FIELD_ELEMENT = '"Element"';
var HEADER_FIELD_ATTRIBUTE = '"Attribut"';
var HEADER_FIELD_CONNECTOR = '"Relation"';
var HEADER_FIELD_CONNECTOR_END = '"Rolle"';
var HEADER_FIELD_DEFINITION = '"Definition"';
var HEADER_FIELD_NOTE = '"Note"';
var HEADER_FIELD_EKSEMPEL = '"Eksempel"';
var HEADER_FIELD_LOVGRUNDLAG = '"Lovgrundlag"';
var HEADER_FIELD_ALTERNATIVT_NAVN = '"Alternativt navn"';

/**
 * Exports the documentation of the model elements on the tagged values definition, scope, lovgrundlag, eksempel and alternativtNavn
 * to 4 CSV files, that can afterwards be combined to one spreadsheet. LibreOffice Calc understands these CSV files without any problems.
 *
 * The CSV files are encoded in UTF-8.
 * 
 * If you want to open the files with Excel instead, then make sure that:
 * -> You change CSV_DELIMITER to the value of List Separator in Control Panel -> Region and Language -> Additional Settings... -> Numbers (Windows 7)
 * and then run the script.
 * -> You open the file via Explorer (double-click or Open with), do not import it.
 *
 * @author Geodatastyrelsen
*/
function main() {
	Repository.EnsureOutputVisible("Script");
	
	var package as EA.Package;
	package = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");	
	
	if (package != null && package.ParentID != 0)	{
		LOGInfo("Working on package '" + package.Name + "' (ID=" + package.PackageID + ")" );
		writeCSVElements(package);
		writeCSVAttributes(package);
		writeCSVEnumerationValues(package);
		writeCSVConnectorEnds(package);
		LOGInfo("Done.");
	}
	else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

function writeCSVElements(package) {
	Session.Prompt("The file you choose in a moment will contain the documentation of the elements (classes, data types, enumerations).", promptOK);
	var fileName = chooseCSVFileDialog("Elementer.csv");
	if (!(fileName == null || fileName == "")) {
		LOGInfo("Exporting to file " + fileName);
		
		var exportColumnHeadings = true;
		var columns;

		columns = Array(7);
		columns[0] = HEADER_FIELD_GUID;
		columns[1] = HEADER_FIELD_ELEMENT;
		columns[2] = HEADER_FIELD_DEFINITION;
		columns[3] = HEADER_FIELD_NOTE;
		columns[4] = HEADER_FIELD_EKSEMPEL;
		columns[5] = HEADER_FIELD_LOVGRUNDLAG;
		columns[6] = HEADER_FIELD_ALTERNATIVT_NAVN;

		initializeCSVEExport(columns, exportColumnHeadings);
		exportElementsToCSV(package);
		finalizeCSVEExport(fileName);
	} else {
		Session.Prompt("No file was specified", promptOK);
	}
}

function exportElementsToCSV(package) {
	var element as EA.Element;
	var elements = getElementsOfPackageAndSubpackages(package);
	
	for (var i = 0; i < elements.length; i++) {
		element = elements[i];
		if (element.Stereotype.substr(0, 2) == "DK" ) {
			var valueMap = CSVECreateEmptyValueMap();
			valueMap.add(HEADER_FIELD_GUID, element.ElementGUID);
			valueMap.add(HEADER_FIELD_ELEMENT, element.Name);
			valueMap.add(HEADER_FIELD_DEFINITION, getTaggedValueElement(element, "definition", ""));
			valueMap.add(HEADER_FIELD_NOTE, getTaggedValueElement(element, "note", ""));
			valueMap.add(HEADER_FIELD_EKSEMPEL, getTaggedValueElement(element, "eksempel", ""));
			valueMap.add(HEADER_FIELD_LOVGRUNDLAG, getTaggedValueElement(element, "lovgrundlag", ""));
			valueMap.add(HEADER_FIELD_ALTERNATIVT_NAVN, getTaggedValueElement(element, "alternativtNavn", ""));
			exportCSVRow(valueMap);
		}
	}
}

function writeCSVAttributes(package) {
	Session.Prompt("The file you choose in a moment will contain the documentation of attributes of classes and data types.", promptOK);
	var fileName = chooseCSVFileDialog("Attributter.csv");
	writeCSVAttributesOrEnumerationValues(package, fileName, true);
}

function writeCSVEnumerationValues(package) {
	Session.Prompt("The file you choose in a moment will contain the documentation of the values of the enumerations.", promptOK);
	var fileName = chooseCSVFileDialog("Enumerationsværdier.csv");
	writeCSVAttributesOrEnumerationValues(package, fileName, false);
}

function writeCSVAttributesOrEnumerationValues(package, fileName, exportAttributes /* boolean */) {
	if (!(fileName == null || fileName == "")) {
		LOGInfo("Exporting to file " + fileName);
		
		var exportColumnHeadings = true;
		var columns;

		columns = Array(8);
		columns[0] = HEADER_FIELD_GUID;
		columns[1] = HEADER_FIELD_ELEMENT;
		columns[2] = HEADER_FIELD_ATTRIBUTE;
		columns[3] = HEADER_FIELD_DEFINITION;
		columns[4] = HEADER_FIELD_NOTE;
		columns[5] = HEADER_FIELD_EKSEMPEL;
		columns[6] = HEADER_FIELD_LOVGRUNDLAG;
		columns[7] = HEADER_FIELD_ALTERNATIVT_NAVN;

		initializeCSVEExport(columns, exportColumnHeadings);
		exportAttributesOrEnumerationValuesToCSV(package, exportAttributes);
		finalizeCSVEExport(fileName);
	} else {
		Session.Prompt("No file was specified", promptOK);
	}
}

function exportAttributesOrEnumerationValuesToCSV(package, exportAttributes) {
	var element as EA.Element;
	var attribute as EA.Attribute;
	var elements = getElementsOfPackageAndSubpackages(package);
	
	for (var i = 0; i < elements.length; i++) {
		element = elements[i];
		if (element.Stereotype.substr(0, 2) == "DK" ) {
			if ((element.Type == "Enumeration" && !exportAttributes) || (element.Type != "Enumeration" && exportAttributes)) {
				createValueMapAndExportCSVRowAttributes(element);
			}
		}
	}
}

function createValueMapAndExportCSVRowAttributes(element) {
	for (var j = 0; j < element.Attributes.Count; j++) {
		attribute = element.Attributes.GetAt(j);
		var valueMap = CSVECreateEmptyValueMap();
		valueMap.add(HEADER_FIELD_GUID, attribute.AttributeGUID);
		valueMap.add(HEADER_FIELD_ELEMENT, element.Name);
		valueMap.add(HEADER_FIELD_ATTRIBUTE, attribute.Name);
		valueMap.add(HEADER_FIELD_DEFINITION, getTaggedValueAttribute(attribute, "definition", ""));
		valueMap.add(HEADER_FIELD_NOTE, getTaggedValueAttribute(attribute, "note", ""));
		valueMap.add(HEADER_FIELD_EKSEMPEL, getTaggedValueAttribute(attribute, "eksempel", ""));
		valueMap.add(HEADER_FIELD_LOVGRUNDLAG, getTaggedValueAttribute(element, "lovgrundlag", ""));
		valueMap.add(HEADER_FIELD_ALTERNATIVT_NAVN, getTaggedValueAttribute(element, "alternativtNavn", ""));
		exportCSVRow(valueMap);
	}
}

function writeCSVConnectorEnds(package) {
	Session.Prompt("The file you choose in a moment will contain the documentation of the association ends.", promptOK);
	var fileName = chooseCSVFileDialog("Relationsender.csv");
	if (!(fileName == null || fileName == "")) {
		LOGInfo("Exporting to file " + fileName);
		
		var exportColumnHeadings = true;
		var columns;

		columns = Array(8);
		columns[0] = HEADER_FIELD_GUID;
		columns[1] = HEADER_FIELD_CONNECTOR;
		columns[2] = HEADER_FIELD_CONNECTOR_END;
		columns[3] = HEADER_FIELD_DEFINITION;
		columns[4] = HEADER_FIELD_NOTE;
		columns[5] = HEADER_FIELD_EKSEMPEL;
		columns[6] = HEADER_FIELD_LOVGRUNDLAG;
		columns[7] = HEADER_FIELD_ALTERNATIVT_NAVN;

		initializeCSVEExport(columns, exportColumnHeadings);
		exportConnectorEndsToCSV(package);
		finalizeCSVEExport(fileName);
	} else {
		Session.Prompt("No file was specified", promptOK);
	}
}

function exportConnectorEndsToCSV(package) {
	var connector as EA.Connector;
	var connectorSource as EA.ConnectorEnd;
	var connectorTarget as EA.ConnectorEnd;
	
	var connectors = getAssociationsOfPackageAndSubpackages(package);
	for (var j = 0; j < connectors.length; j++) {
		connector = connectors[j];
		connectorSource = connector.ClientEnd;
		var valueMap = CSVECreateEmptyValueMap();
		valueMap.add(HEADER_FIELD_GUID, connector.ConnectorGUID);
		valueMap.add(HEADER_FIELD_CONNECTOR, connector.Name);
		valueMap.add(HEADER_FIELD_CONNECTOR_END, connectorSource.Role);
		valueMap.add(HEADER_FIELD_DEFINITION, getTaggedValueConnectorEnd(connector, "definition", true, ""));
		valueMap.add(HEADER_FIELD_NOTE, getTaggedValueConnectorEnd(connector, "note", true, ""));
		valueMap.add(HEADER_FIELD_EKSEMPEL, getTaggedValueConnectorEnd(connector, "eksempel", true, ""));
		valueMap.add(HEADER_FIELD_LOVGRUNDLAG, getTaggedValueConnectorEnd(connector, "lovgrundlag", true, ""));
		valueMap.add(HEADER_FIELD_ALTERNATIVT_NAVN, getTaggedValueConnectorEnd(connector, "alternativtNavn", true, ""));
		exportCSVRow(valueMap);
		
		connectorTarget = connector.SupplierEnd;
		valueMap = CSVECreateEmptyValueMap();
		valueMap.add(HEADER_FIELD_GUID, connector.ConnectorGUID);
		valueMap.add(HEADER_FIELD_CONNECTOR, connector.Name);
		valueMap.add(HEADER_FIELD_CONNECTOR_END, connectorTarget.Role);
		valueMap.add(HEADER_FIELD_DEFINITION, getTaggedValueConnectorEnd(connector, "definition", false, ""));
		valueMap.add(HEADER_FIELD_NOTE, getTaggedValueConnectorEnd(connector, "note", false, ""));
		valueMap.add(HEADER_FIELD_EKSEMPEL, getTaggedValueConnectorEnd(connector, "eksempel", false, ""));
		valueMap.add(HEADER_FIELD_LOVGRUNDLAG, getTaggedValueConnectorEnd(connector, "lovgrundlag", false, ""));
		valueMap.add(HEADER_FIELD_ALTERNATIVT_NAVN, getTaggedValueConnectorEnd(connector, "alternativtNavn", false, ""));
		exportCSVRow(valueMap);
	}
}

main();