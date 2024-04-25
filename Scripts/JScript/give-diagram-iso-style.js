!INC eamt-utilities._logging-utils

// Inside Enterprise Architect: RGB = (blue * 256 + green) * 256 + red
var white = (255 * 256 + 255) * 256 + 255;
var black = (0 * 256 + 0) * 256 + 0;
var regexFontTypeface = /font=[^;]*/;
var isoFontTypeface = "Cambria";
var regexFontSize = /fontsz=[^;]*/;
var isoFontSize = 8 * 10; // pts * 10

/**
 * Make style black-and-white, without using the whiteboard setting because
 * then the symbol for the reading direction is changed to hollow triangle
 * instead of a filled triangle. Use font Cambria size 8.
 *
 * Set the theme to "ISO/TC 211", which must be defined on the workstation
 * this script is run on.
 *
 * @summary Make diagram black-and-white and with the ISO font.
 */
function main() {
	// Show the script output window
	Repository.EnsureOutputVisible("Script");
	
	// Get a reference to the current diagram
	var currentDiagram as EA.Diagram;
	currentDiagram = Repository.GetCurrentDiagram();

	if (currentDiagram == null) {
		throw new Error("Call this script by right-clicking on a diagram");
	}
	giveDiagramElementsAndConnectorsIsoAppearance(currentDiagram);
	
}

function giveDiagramElementsAndConnectorsIsoAppearance(diagram /*EA.Diagram*/) {
	giveDiagramIsoAppearance(diagram);
	
	diagramObjects = diagram.DiagramObjects;
	var diagramObject as EA.DiagramObject;
	var element as EA.Element;
	for (var i = 0; i < diagramObjects.Count; i++) {
		diagramObject = diagramObjects.GetAt(i);
		element = Repository.GetElementByID(diagramObject.ElementID);
		giveElementIsoAppearance(element);
	}
	
	diagramLinks = diagram.DiagramLinks;
	var diagramLink as EA.DiagramLink;
	var connector as EA.Connector;
	for (var i = 0; i < diagramLinks.Count; i++) {
		diagramLink = diagramLinks.GetAt(i);
		connector = Repository.GetConnectorByID(diagramLink.ConnectorID);
		giveConnectorIsoAppearance(connector);
	}
	
	Repository.ReloadDiagram(diagram.DiagramID);
}

function giveDiagramIsoAppearance(diagram /* EA.Diagram */) {
	logStyleEx(diagram.StyleEx);
	LOGDebug("Match: " + diagram.StyleEx.match("Theme=[^:]*:"));
	var newStyleEx = diagram.StyleEx.replace(/Theme=[^:]*:/, "Theme=ISO/TC 211:");
	logStyleEx(newStyleEx);
	diagram.StyleEx = newStyleEx;
	diagram.Update();
}

function logStyleEx(styleEx) {
	var styleExProps = styleEx.split(";");
	LOGDebug("StyleEx:");
	for (var i=1; i < styleExProps.length; i++) {
		LOGDebug(styleExProps[i]);
	}
}

function giveElementIsoAppearance(element /* EA.Element */) {
	/*
	SetAppearance(long Scope, long Item, long Value)

	1 - Base (Default appearance across entire model)

	Item:
	0 - Background color
	1 - Font Color
	2 - Border Color
	3 - Border Width
	*/
	element.SetAppearance(1, 0, white);
	element.SetAppearance(1, 1, black);
	element.SetAppearance(1, 2, black);
	//element.StyleEx = "";
	var originalStyleEx = element.StyleEx;
	var styleExWithFontTypeface;
	if (regexFontTypeface.test(originalStyleEx)) {
		styleExWithFontTypeface = originalStyleEx.replace(regexFontTypeface, "font=" + isoFontTypeface);
	} else {
		styleExWithFontTypeface = "font=" + isoFontTypeface + ";" + originalStyleEx;
	}
	LOGDebug("styleExWithFontTypeface: " + styleExWithFontTypeface);
	var styleExWithFontTypefaceAndFontSize;
	if (regexFontSize.test(styleExWithFontTypeface)) {
		styleExWithFontTypefaceAndFontSize = styleExWithFontTypeface.replace(regexFontSize, "fontsz=" + isoFontSize);
	} else {
		styleExWithFontTypefaceAndFontSize = "fontsz=" + isoFontSize + ";" + styleExWithFontTypeface;
	}
	LOGDebug("styleExWithFontTypefaceAndFontSize: " + styleExWithFontTypefaceAndFontSize);
	element.StyleEx = styleExWithFontTypefaceAndFontSize;
	var updated = element.Update();
	if (updated) {
		LOGInfo(element.Name + " updated");
		element.Refresh();
	} else {
		LOGWarning("Update of " + element.Name + " was unsuccessful");
		LOGWarning("Last error: " + element.GetLastError());
	}
	
}

function giveConnectorIsoAppearance(connector /* EA.Connector */) {
	/*
	SetAppearance(long Scope, long Item, long Value)

	1 - Base (Default appearance across entire model)

	Item:
	0 - Background color
	1 - Font Color
	2 - Border Color
	3 - Border Width
	*/
	connector.Color = black;
	connector.Update();
}

main();