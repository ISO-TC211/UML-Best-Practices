!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

var STEREOTYPE_APPLICATION_SCHEMA = "DKDomænemodel";

/**
* Runs the model searches decribed on http://wiki.gst.dk/Tjekliste_til_datamodellering described in paragraph "Modeltjeks".
*
* @author Geodatastyrelsen
*/
function main() {
	// Show the script output window
	Repository.EnsureOutputVisible("Script");

	// Get the currently selected package in the tree to work on
	var package as EA.Package;
	package = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	if (package != null && package.ParentID != 0) {
		LOGInfo("Working on package '" + package.Name + "' (ID=" +
			package.PackageID + ")");
		var results = [];
		results[0] = ["Validation name", "Validation result"]; // header
		runModelSearches(results);
		displayResults(results);
		LOGInfo("Done.")
	} else {
		Session.Prompt( "This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK );
	}
}

function runModelSearches(results) {
	LOGInfo("Running model searches");
	/* Needs to corresponds with the list on the wiki in paragraph "Modeltjeks" sorted by column "Søgning". */
	var searchNames = [
	"val_attribute_definition",
	"val_attribute_name",
	"val_attribute_scope",
	"val_attribute_type",
	"val_class_definition",
	"val_class_name",
	"val_class_scope",
	"val_connector_end_definition",
	"val_connector_end_multiplicity",
	"val_connector_end_name",
	"val_connector_end_navigability",
	"val_connector_name",
	"val_diagram_notes",
	"val_element_language",
	"val_enumeration_attributes_literals",
	"val_find_orphans",
	"val_navigability_aggregations_and_compositions",
	"val_package_is_namespace",
	"val_package_name"
	];
	for (var i in searchNames) {
		showAndValidateSearchResults(searchNames[i], results);
	}
}

function showAndValidateSearchResults(searchName, results) {
	Repository.RunModelSearch(searchName, "", "", "");
	var output = Session.Prompt("Are the results of " + searchName + " ok?", promptYESNO);
	if (output == resultYes) {
		results.push([searchName, "pass"]);
	} else {
		results.push([searchName, "FAIL"]);
	}
}

function displayResults(results) {
	var resultString = "";
	for (var i in results) {
		resultString += results[i][0] + ": " + results[i][1] + "\r\n";
	}
	LOGInfo("Result:\r\n" + resultString);
}

main();