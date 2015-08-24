!INC Local Scripts.EAConstants-JScript
!INC _ModelHelperFunctions
!INC _PropertiesHelperFunctions
!INC EAScriptLib.JScript-Logging

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

/**
 * Validates that all associations, aggregations and composition have a reading order indicated, and that it
 * is the same on all diagrams. Takes into account that fact that connectors/labels may be suppressed on diagrams.
 * 
 * @author Geodatastyrelsen
 */
function main() {
	Repository.EnsureOutputVisible("Script");

	var package as EA.Package;
	package = Repository.GetTreeSelectedPackage();
	
	LOGInfo("=======================================");
	if (package != null && package.ParentID != 0) {
		LOGInfo("Working on package '" + package.Name + "' (ID=" +
			package.PackageID + ")");
		validateReadingOrderAssociations(package);
		LOGInfo("Done.")
	} else {
		Session.Prompt("This script requires a package to be selected in the Project Browser.\n" +
			"Please select a package in the Project Browser and try again.", promptOK);
	}
}

function validateReadingOrderAssociations(package /* EA.Package*/) { /*: boolean */
	var noOfErrorsFound = 0;
	var diagrams = getDiagramsOfPackageAndSubpackages(package);
	var diagram as EA.Diagram;
	var diagramLinks as EA.Collection;
	
	var readingOrderDictionary = new ActiveXObject("Scripting.Dictionary");
	for (i in diagrams) {
		diagram = diagrams[i];
		var styleExDictionary = createDictionaryFromKeyValuePairs(diagram.StyleEx, ";", "=");
		var pdataDictionary = createDictionaryFromKeyValuePairs(diagram.ExtendedStyle, ";", "=");
		var continueValidation = true;
		var suppConnectorLabels = styleExDictionary.Item("SuppConnectorLabels");
		if (suppConnectorLabels == null || suppConnectorLabels === "1") { // see Attribute Values - styleex & pdata in EA User Guide
			continueValidation = false;
			LOGInfo('Checkbox "Suppress All Connector Labels" + is selected for diagram ' + diagram.Name + ", skipping validation");
		}
		var hideRel = pdataDictionary.Item("HideRel");
		if (hideRel == null || hideRel === "1") { // see Attribute Values - styleex & pdata in EA User Guide
			continueValidation = false;
			LOGInfo('Checkbox "Show Relationships" + is not selected for diagram ' + diagram.Name + ", skipping validation");
		}
		if (continueValidation) {
			LOGInfo("Validating associations/aggregations/compositions on diagram " + diagram.Name);
			diagramLinks = diagram.DiagramLinks;
			var diagramLink as EA.DiagramLink;
			var connector as EA.Connector;
			for (var j = 0; j < diagramLinks.Count; j++) {
				diagramLink = diagramLinks.GetAt(j);				
				if (!diagramLink.IsHidden) {
					connector = Repository.GetConnectorByID(diagramLink.ConnectorID);
					if (connector.Type == "Association" || connector.Type == "Aggregation") {
						LOGDebug("Validating " + connector.Name);
						var labelDictionary = createDiagramLinkLabelDictionary(diagramLink);
						LOGTrace("\r\n" + formatDiagramLinkLabelDictionary(labelDictionary));
						var labelAttributesForConnectorName = labelDictionary.Item("LMT");
						
						var hidden = labelAttributesForConnectorName.Item("HDN");
						var isHidden = hidden != null && hidden === "1";
						
						var readingOrder = labelAttributesForConnectorName.Item("DIR");
						var hasReadingOrder = readingOrder != null && (readingOrder === "1" || readingOrder === "-1");
						
						if (!isHidden && !hasReadingOrder) {
							noOfErrorsFound++;
							LOGError("Association " + connector.Name + " on diagram " + diagram.Name + " in package " + package.Name + " does not have its reading order indicated.");
						}
						if (hasReadingOrder) {
							if (readingOrderDictionary.Exists(connector.ConnectorID)) {
								if (readingOrder != readingOrderDictionary.Item(connector.ConnectorID)) {
									noOfErrorsFound++;
									var message = "Association " + connector.Name + " on diagram " + diagram.Name + " in package " + package.Name + " has indicated a different reading order on this diagram than on an earlier processed diagram.";
									message += "\r\nNote that this scripts also checks the hidden labels, you may have to unhide labels in order to correct this error.";
									LOGError(message);
								}
							} else {
								readingOrderDictionary.Add(connector.ConnectorID, readingOrder);
							}
						}
					}
				}
			}
		}
	}
	LOGInfo(noOfErrorsFound + " error(s) found in validatereadingOrderAssociations.");
}

main();