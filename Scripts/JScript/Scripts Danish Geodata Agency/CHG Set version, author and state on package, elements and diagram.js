!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _TaggedValuesHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;
 
var newVersion;
var newAuthor;
var newStatus;
 
/**
* Updates the version, author and status on all elements in this package and its subpackages.
* If the package has stereotype DKDomænemodel, the tagged value version is also updated.
*
* @author Geodatastyrelsen
*/
function main()
{
	// Show the script output window
	Repository.EnsureOutputVisible("Script");

	// Get the currently selected package in the tree to work on
	var selectedPackage as EA.Package;
	selectedPackage = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	
	if (selectedPackage != null && selectedPackage.ParentID != 0) {
		var testElementID = 0;
		
		LOGInfo("=======================================");
		LOGInfo("Working on package '" + selectedPackage.Name + "' (ID=" +
			selectedPackage.PackageID + ")");
		
		requestInput(selectedPackage);
		updateVersionAuthorAndStatus(selectedPackage);
		var package as EA.Package;
		for (var i=0; i < selectedPackage.Packages.Count; i++) {
			package = selectedPackage.Packages.GetAt(i);
			updateVersionAuthorAndStatus(package);
		}
		
		LOGInfo( "Done!" );
	}
	else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

function requestInput(selectedPackage) {
	newVersion = Session.Input("Version of " + selectedPackage.Name);
	if (newVersion.length == 0) {
		LOGError("No version given");
		return;
	}
	newAuthor = Session.Input("Author of " + selectedPackage.Name);
	if (newAuthor.length == 0) {
		LOGError("No author given");
		return;
	}
	newStatus = Session.Input("Status of " + selectedPackage.Name + " (Approved or Proposed)");
	if (newStatus != 'Approved' && newStatus != 'Proposed') {
		LOGError("Wrong new status '" + newStatus + "', should be 'Approved' or 'Proposed'");
		return;
	}						
}

function updateVersionAuthorAndStatus(package) {
	setFieldsOnPackage(package);
		
	var elements as EA.Collection;
	elements = package.Elements;
	for (var i = 0 ; i < elements.Count ; i++) {
		var currentElement as EA.Element;
		currentElement = elements.GetAt(i);
		setFieldsOnElement(currentElement);
	}
	package.Elements.Refresh();
	
	var diagrams as EA.Collection;
	diagrams = package.Diagrams;
	for (var i = 0 ; i < diagrams.Count ; i++) {
		var currentDiagram as EA.Diagram;
		currentDiagram = diagrams.GetAt(i);
		setFieldsOnDiagram(currentDiagram);
	}
	package.Diagrams.Refresh();
}

function setFieldsOnPackage(package) {
	package.Element.Author = newAuthor;
	package.Version = newVersion;
	package.Element.Status = newStatus;
	if (package.Element.Stereotype == "DKDomænemodel") {
		setTaggedValueElement(package.Element, "version", newVersion);
	}
	package.Element.Update();
	package.Update();
	LOGDebug("Set author, version and status on: " + package.Name);
}

function setFieldsOnElement(element) {
	element.Author = newAuthor;
	element.Version = newVersion;
	element.Status = newStatus;
	element.Update();
	LOGDebug("Set author, version and status on: " + element.Name);
}

function setFieldsOnDiagram(diagram) {
	diagram.Author = newAuthor;
	diagram.Version = newVersion;
	diagram.Update();
	LOGDebug("Set author and version on: " + diagram.Name);
}

main();