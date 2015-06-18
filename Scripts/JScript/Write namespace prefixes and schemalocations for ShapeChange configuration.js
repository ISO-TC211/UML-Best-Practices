!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

var writeFullPath;

/**
* This scripts writes the namespace properties, present in the tagged values xmlns, targetNamespace and xsdDocument
* for use in the ShapeChange configuration file (see also http://shapechange.net/targets/xsd/#Namespace_Identifiers):
* <XmlNamespace ns="mynamespace" nsabr="mynamespaceprefix" location="physicallocationofmyxmlschemafile" />
*
* Select the package that contains the namespace(s) you want to write this information down for. Copy the relevant parts of 
* the script output to your ShapeChange configuration and adapt where needed.
* 
* If there is a predefined and logical structure in the schema locations, e.g. when it follows the XML target namespace, then
* choose Yes when the script asks "Write the full path of the XML Schema files?". Else choose No, and update the locations manually
* afterwards with the actual locations of the GML application schemas.
*
* @author Heidi Vanparys
*/
function main()
{
	Repository.ClearOutput("Script");
	Repository.EnsureOutputVisible("Script");

	// Get the currently selected package in the tree to work on
	var selectedPackage as EA.Package;
	selectedPackage = Repository.GetTreeSelectedPackage();
	
	LOGInfo( "=======================================" );
	LOGInfo(_LOGGetDisplayDate());
	
	if (selectedPackage != null) {		
		LOGInfo("Application schemas in package '" + selectedPackage.Name + "' (ID=" +
			selectedPackage.PackageID + ") (copy the following lines to your ShapeChange configuration)");
		
		var promptResult = Session.Prompt("Write the full path of the XML Schema files?", promptYESNO);
		if (promptResult == resultYes) {
			writeFullPath = true;
		} else if (promptResult == resultNo) {
			writeFullPath = false;
		} else {
			LOGInfo("No answer given, stop script.");
			return;
		}
		
		writeTaggedValuesOfApplicationSchemas(selectedPackage);
		
		LOGInfo("Done!");
	}
	else {
		Session.Prompt( "This script requires a model or package to be selected in the Project Browser.\n" +
			"Please select a package or model in the Project Browser and try again.", promptOK );
	}
}

function writeTaggedValuesOfApplicationSchemas(aPackage) {
	var isApplicationSchema;
	if (aPackage.Element == null || aPackage.Element.Stereotype != 'applicationSchema') {
		isApplicationSchema = false;
	} else {
		isApplicationSchema = true;
	}
	
	if (isApplicationSchema) {
		writeTaggedValues(aPackage);		
	} else {
		if (aPackage.Packages.Count > 0) {
			for (var i = 0; i < aPackage.Packages.Count; i++) {
				writeTaggedValuesOfApplicationSchemas(aPackage.Packages.GetAt(i));
			}
		}
	}
}

function writeTaggedValues(aPackage) {
	var targetNamespace = '';
	var nsabr = '';
	var xsdDocument = '';
	var namespace;
	for (var i = 0; i < aPackage.Element.TaggedValues.Count; i++) {
		tag = aPackage.Element.TaggedValues.GetAt(i);
		if (tag.Name == 'targetNamespace') {
			targetNamespace = tag.Value;
		}
		if (tag.Name == 'xmlns') {
			nsabr = tag.Value;
		}
		if (tag.Name == 'xsdDocument') {
			xsdDocument = tag.Value;
		}
		
	}
	namespace = "<XmlNamespace " + "ns=\"" + targetNamespace + "\" " + "nsabr=\"" + nsabr + "\" " + "location=\""
	if (writeFullPath) {
		namespace = namespace + targetNamespace + "/";
	}
	namespace = namespace + xsdDocument + "\" " + "/>";
	Session.Output(namespace);
}

main();