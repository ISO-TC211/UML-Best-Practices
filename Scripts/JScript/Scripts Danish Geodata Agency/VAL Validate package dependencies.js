!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Logging
!INC _ModelHelperFunctions

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

var STEREOTYPE_APPLICATION_SCHEMA = "DKDomænemodel";
var PACKAGE_DIAGRAM_PREFIX = "Pakkeafhængigheder ";

/**
* For use on application schemas.
* 
* Validates that:
* -> the selected package has a package dependencies diagram
* -> the packages the selected package depends upon are present in the package dependency diagram
* -> a usage is modelled towards the packages the selected package depends upon
* -> no usage is modelled towards packages the selected packages does not depend upon
*
* Usage:
* "A usage is a relationship in which one element requires another element (or set of elements) for its full implementation or
* operation. In the metamodel, a Usage is a Dependency in which the client requires the presence of the supplier."
* -> see section 7.3.54 in UML Superstructure Specification, v2.4.1
* -> see http://www.uml-diagrams.org/dependency.html#usage
*
* When a package depends on an element in a subpackage of an ISO standard, the package representing the ISO
* standard itself is treated as the supplier, not that subpackage. When a package depends on an element
* in a subpackage of another application schema, the application schema itself is treated as the supplier, 
* not that subpackage.
*
* When getting the error "Internal application error" in lines that call functions like Repository.GetElementByID(),
* then do a Get All Lastest and forcing a full import of all the XMI files.
*
* @author Geodatastyrelsen
*/ 
function main() {
	Repository.EnsureOutputVisible("Script");
	
	var package as EA.Package;
	package = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");	
	if (package != null && package.ParentID != 0 && package.Element.Stereotype == STEREOTYPE_APPLICATION_SCHEMA) {
		LOGInfo("Working on package '" + package.Name + "' (ID=" + package.PackageID + ")");
		validatePackageDependencies(package);
		LOGInfo("Done.");
	} else {
		Session.Prompt("This script requires an application schema to be selected in the Project Browser.\n" +
			"Please select a an application schema in the Project Browser and try again.", promptOK);
	}
}

/**
* Main validation method, can be called from other scripts.
*
* Returns whether or not the validation succeeded.
*/
function validatePackageDependencies(package /* EA.Package*/) { /*: boolean */
	var determinedMainSuppliers = determineMainSuppliersFromModel(package);
	var modelledSuppliers = retrieveModelledSuppliers(package);
	
	LOGInfo("=== Validation results ===");
	var noOfErrorsFound = 0;
	noOfErrorsFound += validatePackageDependencyDiagram(package, determinedMainSuppliers);
	noOfErrorsFound += validateUsagesModelledForDeterminedMainSuppliers(package, determinedMainSuppliers, modelledSuppliers);
	noOfErrorsFound += validateNoOtherUsagesModelled(package, determinedMainSuppliers, modelledSuppliers);
	noOfErrorsFound += validateNoOtherConnectorsModelled(package);

	LOGInfo(noOfErrorsFound + " error(s) found in validatePackageDependencies.");
	return noOfErrorsFound == 0;
}

/**
* Validates that:
* -> a package diagram is present
* -> the main suppliers are present on it
*/
function validatePackageDependencyDiagram(package /* EA.Package */, determinedMainSuppliers /* Scripting.Dictionary */) { /*: integer */
	var noOfErrorsFound = 0;
	var requiredPackageDiagramName = getPackageDiagramName(package);
	var packageDependencyDiagram = getPackageDependencyDiagram(package);
	if (packageDependencyDiagram == null) {
		noOfErrorsFound++;
		LOGError("No diagram with name " + requiredPackageDiagramName + " present.");
	} else {
		var diagramType = packageDependencyDiagram.Type;
		if (diagramType != "Package") {
			noOfErrorsFound++;
			LOGError("The diagram type of " + packageDependencyDiagram.Name + ' must be "Package" ' + ", not " + diagramType);
		}
		
		var diagramObjects as EA.Collection;
		var diagramObject as EA.DiagramObject;
		diagramObjects = packageDependencyDiagram.DiagramObjects;
		var keysD = (new VBArray(determinedMainSuppliers.Keys())).toArray();
		for (var i in keysD) {
			var presentInDiagram = false;
			for (var j = 0; j < diagramObjects.Count; j++) {
				diagramObject = diagramObjects.GetAt(j);
				if (diagramObject.ElementID == determinedMainSuppliers.Item(keysD[i]).Element.ElementID) {
					presentInDiagram = true;
				}
			}
			if (!presentInDiagram) {
				noOfErrorsFound++;
				LOGError(determinedMainSuppliers.Item(keysD[i]).Name + " is missing in diagram " + requiredPackageDiagramName);
			}
		}
	}
	return noOfErrorsFound;
}

function validateUsagesModelledForDeterminedMainSuppliers(package /* EA.Package */, determinedMainSuppliers /* Scripting.Dictionary */, modelledSuppliers /* Scripting.Dictionary */) { /*: integer */
	var noOfErrorsFound = 0;
	var keysD = (new VBArray(determinedMainSuppliers.Keys())).toArray();
	for (var i in keysD) {
		if (!modelledSuppliers.Exists(keysD[i])) {
			noOfErrorsFound++;
			var determinedSupplierName = determinedMainSuppliers.Item(keysD[i]).Name;
			var message = package.Name + " uses one or more elements from package " + determinedSupplierName + "\r\nbut no usage dependency is present in the model.";
			message += "\r\nAction: Add the usage dependency to the model.";
			message += "\r\nNote: Check whether a dependency with or without stereotype <<use>> is present between those packages and convert it to a usage dependency if needed.";
			LOGError(message);
		} else {
			
		}
	}
	return noOfErrorsFound;
}

function validateNoOtherUsagesModelled(package /* EA.Package */, determinedMainSuppliers /* Scripting.Dictionary */, modelledSuppliers /* Scripting.Dictionary */) {/*: integer */
	var noOfErrorsFound = 0;
	var keysM = (new VBArray(modelledSuppliers.Keys())).toArray();
	for (var i in keysM) {
		if (!determinedMainSuppliers.Exists(keysM[i])) {
			noOfErrorsFound++;
			var modelledSupplierName = modelledSuppliers.Item(keysM[i]).Name;
			LOGError(package.Name + " has a usage on package " + modelledSupplierName + "\r\n in the model but it does not actually depend on it.\r\nAction: Remove the usage dependency from the model.");
		}
	}
	return noOfErrorsFound;
}

function validateNoOtherConnectorsModelled(package /* EA.Package */) {/*: integer */
	var noOfErrorsFound = 0;
	var connectors = package.Connectors;
	var connector as EA.Connector;
	for (var i = 0; i < connectors.Count; i++) {
		connector = connectors.GetAt(i);
		if (connector.Type != "Usage") {
			var relatedElement as EA.Element;
			var relatedPackage as EA.Package;
			if ((package.Element.ElementID == connector.ClientID && connector.SupplierEnd.IsNavigable) ||
				(package.Element.ElementID == connector.SupplierID && connector.ClientEnd.IsNavigable)) {
				// only consider connectors from the given package to another package, not the other way round
				relatedElement = Repository.GetElementByID(connector.SupplierID);
				relatedPackage = Repository.GetPackageByGuid(relatedElement.ElementGUID);
				noOfErrorsFound++;
				var message = package.Name + " has the following connector towards package " + relatedPackage.Name + " but that one should not be present:";
				message += "\r\nConnectorGUID=" + connector.ConnectorGUID + ";ConnectorID=" + connector.ConnectorID + ";Type=" + connector.Type + ";Stereotype=" + connector.Stereotype;
				message += "\r\nAction: remove the connector or replace it with a usage (check the other error messages)";
				LOGError(message);
			}
		}
	}
	return noOfErrorsFound;
}

function getPackageDiagramName(package /* EA.Package */) {
	return PACKAGE_DIAGRAM_PREFIX + package.Name;
}

function getPackageDependencyDiagram(package /* EA.Package */) {
	var requiredPackageDiagramName = getPackageDiagramName(package);
	var diagrams as EA.Collection;
	diagrams = package.Diagrams;
	var packageDependencyDiagram as EA.Diagram;
	for (var i = 0; i < diagrams.Count; i++) {
		if (diagrams.GetAt(i).Name == requiredPackageDiagramName) {
			packageDependencyDiagram = diagrams.GetAt(i);
			break;
		}
	}
	return packageDependencyDiagram;
}

/**
* Determines the main suppliers (packages) of the given package by looking at the attributes and relations of the elements in it.
*/
function determineMainSuppliersFromModel(package /* EA.Package */) { /*: Scripting.Dictionary */
	var elements = getElementsOfPackageAndSubpackages(package);
	var suppliers = new ActiveXObject("Scripting.Dictionary");
	var mainSuppliers = new ActiveXObject("Scripting.Dictionary");
	
	addSuppliersThroughAttributes(elements, suppliers);
	addSuppliersThroughAssociations(elements, suppliers);
	convertSuppliersToMainSuppliers(suppliers, mainSuppliers);
	ensureNoSelfDependencies(package, mainSuppliers);
	LOGInfo("Suppliers retrieved from model for package " + package.Name + ":");
	outputDictionaryOfPackages(mainSuppliers);
	return mainSuppliers;
}

function retrieveModelledSuppliers(package /* EA.Package */) { /*: Scripting.Dictionary */
	var usageSuppliers = new ActiveXObject("Scripting.Dictionary");
	var connectors = package.Connectors;
	for (var i = 0; i < connectors.Count; i++) {
		var connector = connectors.GetAt(i);
		if (connector.Type == "Usage") {
			var relatedElement as EA.Element;
			var relatedPackage as EA.Package;
			if ((package.Element.ElementID == connector.ClientID && connector.SupplierEnd.IsNavigable) ||
				(package.Element.ElementID == connector.SupplierID && connector.ClientEnd.IsNavigable)) {
				// only consider suppliers of the given package, not clients
				relatedElement = Repository.GetElementByID(connector.SupplierID);
				relatedPackage = Repository.GetPackageByGuid(relatedElement.ElementGUID);
				if (usageSuppliers.Exists(relatedPackage.PackageID)) {
					LOGWarning("More than one usage dependency is present between " + package.Name + " and " + relatedPackage.Name + ".");
				}
				addPackageIfNotYetPresent(usageSuppliers, relatedPackage);
			}
		}
	}
	LOGInfo("Different usages modelled for package " + package.Name + ":");
	outputDictionaryOfPackages(usageSuppliers);
	return usageSuppliers;
}

function addPackageIfNotYetPresent(packages /* Scripting.Dictionary */, package /* EA.Package */) {
	if (!packages.Exists(package.PackageGUID)) {
		packages.Add(package.PackageGUID, package);
	}
}

/**
* Adds the packages that contain the types of the attributes of the given elements.
*/
function addSuppliersThroughAttributes(elements, suppliers) {
	var supplier as EA.Package;
	var element as EA.Element;
	
	for (var i in elements) {
		element = elements[i];
		var attributes;
		var attribute as EA.Attribute;
		for (var j = 0; j < element.Attributes.Count; j++) {
			attribute = element.Attributes.GetAt(j);
			var classifierID = attribute.ClassifierID;
			if (classifierID != 0) {
				var referencedElement = Repository.GetElementByID(classifierID);
				supplier = Repository.GetPackageByID(referencedElement.PackageID);
				LOGDebug(element.Name + "." + attribute.Name + " is type of " + getPathnameOfElement(referencedElement));
				addPackageIfNotYetPresent(suppliers, supplier);
			}
		}
	}	
}

/**
* Adds the packages that contain the types of the navigable member ends of the given elements.
*/
function addSuppliersThroughAssociations(elements, suppliers) {
	var supplier as EA.Package;
	var element as EA.Element;
	
	for (var i in elements) {
		element = elements[i];
		var connector as EA.Connector;
		for (var j = 0; j < element.Connectors.Count; j++) {
			connector = element.Connectors.GetAt(j);
			if (connector.Type == "Association" || connector.Type == "Aggregation") {
				if (element.ElementID == connector.ClientID && connector.SupplierEnd.IsNavigable) {
					var relatedElement = Repository.GetElementByID(connector.SupplierID);
					supplier = Repository.GetPackageByID(relatedElement.PackageID);
					LOGDebug(element.Name + "." + connector.SupplierEnd.Role + " is type of " + getPathnameOfElement(relatedElement));
					addPackageIfNotYetPresent(suppliers, supplier);
				} else if (element.ElementID == connector.SupplierID && connector.ClientEnd.IsNavigable) {
					var relatedElement = Repository.GetElementByID(connector.ClientID);
					supplier = Repository.GetPackageByID(relatedElement.PackageID);
					LOGDebug(element.Name + "." + connector.ClientEnd.Role + " is type of " + getPathnameOfElement(relatedElement));
					addPackageIfNotYetPresent(suppliers, supplier);
				}
			}
		}
	}
}

/**
* Takes only specifc versions of adopted ISO standards into account, not drafts nor packages gathering different versions of a standard.
*
* Examples of package names that will return true:
* -> ISO 19103:2015 Conceptual schema language
* -> ISO 19115-2:2009 Metadata - Imagery
* -> ISO 00639 Language Codes
*
* Examples of package names that will return false:
* -> ISO CD 19107 Spatial Schema
* -> ISO 19103 All
*/
function isISOPackage(package /* EA.Package */) { /*: boolean */
	var packageName = package.Name;
	// use forward slash notation for regex so backslash does not have to be escaped
	var regExp = /ISO (19\d{3}(-\d)?:\d{4}|[0,2-9][0-8]\d{3}) .*/;
	var isISO = regExp.test(packageName);
	return isISO;
}

/*
* Returns whether this package is a "main" package, that is, a package representing an ISO standard or an application schema.
*/
function isMainPackage(package /* EA.Package */) { /*: boolean */
	var packageName = package.Name;
	if (package.ParentID == 0) { // package is a model (has no parent), thus is not a main package
		isMain = false;
	} else {
		var isISO = isISOPackage(package);
		var stereotype = package.Element.Stereotype;
		var isApplicationSchema = (stereotype == STEREOTYPE_APPLICATION_SCHEMA);
		var isMain = isISO || isApplicationSchema;
	}
	return isMain;
}

/**
* Goes through the initial suppliers and keeps them or replaces it by one of it ancestors.
*/
function convertSuppliersToMainSuppliers(suppliers, mainSuppliers) {
	var keys = (new VBArray(suppliers.Keys())).toArray();
	for (var i in keys) {
		var supplier = suppliers.Item(keys[i]);
		var supplierName = supplier.Name;
		var mainSupplierAdded = false;
		if (isMainPackage(supplier)) {
			LOGDebug("Keeping " + supplierName);
			addPackageIfNotYetPresent(mainSuppliers, supplier);
			mainSupplierAdded = true;
		} else {
			var currentPackage as EA.Package;
			var parentPackage as EA.Package;
			var parentPackageName;
			currentPackage = supplier;
			while (currentPackage.ParentID != 0) {
				parentPackage = Repository.GetPackageByID(currentPackage.ParentID);
				parentPackageName = parentPackage.Name;
				if (isMainPackage(parentPackage)) {
					LOGDebug("Using " + parentPackageName + " instead of " + supplierName);
					addPackageIfNotYetPresent(mainSuppliers, parentPackage);
					mainSupplierAdded = true;
					break;
				}
				currentPackage = parentPackage;
			}																					
		}
		
		if (!mainSupplierAdded) {
			LOGDebug("Keeping " + supplierName);
			addPackageIfNotYetPresent(mainSuppliers, supplier);
		}
	}
}

function outputDictionaryOfPackages(dictionaryOfPackages) {
	var text = "";
	var items = (new VBArray(dictionaryOfPackages.Items())).toArray();
	var sortedItems = [].concat(items).sort(sortPackagesByName);
	for (var i in sortedItems) {
		text += sortedItems[i].Name + "\r\n";
	}
	LOGInfo(text);
}

/**
* A package must not have itself as a supplier.
*/
function ensureNoSelfDependencies(package, suppliers) {
	if (suppliers.Exists(package.PackageGUID)) {
		suppliers.Remove(package.PackageGUID);
	}
}

/**
* Helper function to be used in the sort method of Arrays (of packages).
*/
function sortPackagesByName(package1 /* EA.Package */, package2 /* EA.Package */) {
	return package1.Name.localeCompare(package2.Name);
}

main();