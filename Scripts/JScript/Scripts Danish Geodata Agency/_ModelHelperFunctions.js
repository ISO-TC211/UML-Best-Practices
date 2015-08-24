!INC Local Scripts.EAConstants-JScript
!INC _VersionControlHelperFunctions

/**
 * Note: the subpackages of the given package are not included in the result.
 */
function getElementsOfPackageAndSubpackages(aPackage /* : EA.Package */) { /* : Array of Elements */
	var elements = [];
	for (var i = 0; i < aPackage.Elements.Count; i++) {
		elements[i] = aPackage.Elements.GetAt(i);
	}
	for (var j = 0; j < aPackage.Packages.Count; j++) {
		elements = elements.concat(getElementsOfPackageAndSubpackages(aPackage.Packages.GetAt(j)));
	}
	return elements;
}

function getDiagramsOfPackageAndSubpackages(aPackage /* : EA.Package */) { /* : Array of Diagrams */
	var diagrams = new Array();
	for (var i = 0; i < aPackage.Diagrams.Count; i++) {
		diagrams[i] = aPackage.Diagrams.GetAt(i);
	}
	for (var j = 0; j < aPackage.Packages.Count; j++) {
		diagrams = diagrams.concat(getDiagramsOfPackageAndSubpackages(aPackage.Packages.GetAt(j)));
	}
	return diagrams;
}

function getSubpackagesOfPackage(aPackage /* : EA.Package */) { /* : Array of Packages */
	var packages = [];
	for (var i = 0; i < aPackage.Packages.Count; i++) {
		packages = packages.concat(aPackage.Packages.GetAt(i), getSubpackagesOfPackage(aPackage.Packages.GetAt(i)));
	}
	return packages;
}

/**
* Get the associations (including the aggregations and compositions) that are version
* controlled in the given package or one of its subpackages.
*/
function getAssociationsOfPackageAndSubpackages(aPackage /* EA.Package */) { /* Array of Connectors */
	var element as EA.Element;
	var connector as EA.Connector;
	var addToMap; /* boolean */
	
	var elements = getElementsOfPackageAndSubpackages(aPackage);
	var connectorMap = new ActiveXObject("Scripting.Dictionary");
	var connectors = new Array();
	
	for (var i = 0; i < elements.length; i++) {
		element = elements[i];
		for (var j = 0; j < element.Connectors.Count; j++) {
			connector = element.Connectors.GetAt(j);
			addToMap = isConnectorAssociationAndControlledInSamePackageAsElement(connector, element);
			if (addToMap) {
				if (!connectorMap.Exists(connector.ConnectorGUID)) {
					connectorMap.Add(connector.ConnectorGUID, connector);
				}
			}
		}
	}
	// see also https://msdn.microsoft.com/en-us/library/8aet97f2%28v=vs.84%29.aspx for syntax
	return (new VBArray(connectorMap.Items())).toArray();
}

/**
* Returns the full path name of the given element (OCL style, see section 7.5.7 of the specification).
*/
function getPathnameOfElement(anElement /* EA.Element */) { /* String */
	var package as EA.Package;
	package = Repository.GetPackageByID(anElement.PackageID);
	var pathname = package.Name + "::" + anElement.Name;
	do {
		package = Repository.GetPackageByID(package.ParentID);
		pathname = package.Name + "::" + pathname;
	} while (package.ParentID != 0)
	return pathname;
}