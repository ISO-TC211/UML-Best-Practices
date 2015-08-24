/**
 * Creates a dictionary from a string containing a series of key-value pairs.
 *
 * Example: key1=value1;key2=value2;key3=value3;
 */
function createDictionaryFromKeyValuePairs(string, separator1, separator2) { /*: Scripting.Dictionary */
	var dictionary = new ActiveXObject("Scripting.Dictionary");
	var keyValuePairs = string.split(separator1);
	for (var i in keyValuePairs) {
		if (keyValuePairs[i].length != 0) {
			// if the incoming string ends with separator1, the last element in the array will be an empty string
			// takes also into account the following siutation: the string may also contain 2 times separator1 without
			// anything in between, e.g. key1=value1;;key3=value3
			var keyValuePair = keyValuePairs[i].split(separator2);
			dictionary.Add(keyValuePair[0], keyValuePair[1]);
		}
	}
	return dictionary;
}

/**
 * Creates a dictionary of the attributes (alignment, formatting, etc.) of the labels of a connector on a diagram.
 * 
 * The dictionary is on two levels:
 *   First level: LLB, LLT, LMT, LMB, LRT, LRB, IRHS, ILHS
 *   Second level: CX, CY, OX, OY, HDN, BLD, ITA, UND, CLR, ALN, DIR, ROT
 *
 * See more here:
 * -> http://www.sparxsystems.com/cgi-bin/yabb/YaBB.cgi?num=1185185815/9#9
 * -> book Inside Enterprise Architect, section Non-Standard Connectors: t_diagramlinks
 */
function createDiagramLinkLabelDictionary(diagramLink /* EA.DiagramLinks */) {  /*: Scripting.Dictionary */
	var dictionary = new ActiveXObject("Scripting.Dictionary");
	var labelsString =  _getLabelsString(diagramLink);
	dictionary = _createDiagramLinkLabelDictionary(labelsString);
	return dictionary;
}

/**
 * Creates a formatted dictionary of the attributes of the labels of a connector on a diagram. E.g. for use in logging/debugging.
 */
function formatDiagramLinkLabelDictionary(dictionary) { /*: String */
	var output = "";
	var array = (new VBArray(dictionary.Keys())).toArray();
	for (var a in array) {
		output += array[a] + "\r\n";
		dictionary2 = dictionary.Item(array[a]);
		var array2 = (new VBArray(dictionary2.Keys())).toArray();
		for (var a2 in array2) {
			output += "    " + array2[a2] + "=" + dictionary2.Item(array2[a2]) + "\r\n";
		}
	}
	return output;
}

/**
 * "Private" function, for use in this script only.
 */
function _getLabelsString(diagramLink) {
	var geometry = diagramLink.Geometry;
	var splitGeometryDollarSign = geometry.split("$");
	var labelsString = splitGeometryDollarSign[1];
	return labelsString;
}

/**
 * "Private" function, for use in this script only.
 */
function _createDiagramLinkLabelDictionary(labelsString) { /*: Scripting.Dictionary */
	var labelDictionary = new ActiveXObject("Scripting.Dictionary");
	if (labelsString != null) {
		var splitLabelSemiColon = labelsString.split(";");
		for (var k in splitLabelSemiColon) {
			if (splitLabelSemiColon[k].length > 0) {
				var labelString = splitLabelSemiColon[k];
				LOGTrace("Label: " + labelString);
				var indexOfFirstEqualsSign = labelString.indexOf("=");
				var labelName = labelString.substr(0, indexOfFirstEqualsSign);
				if (labelString.length >= indexOfFirstEqualsSign + 1) {
					var labelAttributes = labelString.substr(indexOfFirstEqualsSign + 1);
					var attributeDictionary = createDictionaryFromKeyValuePairs(labelAttributes, ":", "=");
				}
				labelDictionary.Add(labelName, attributeDictionary);
			}
		}
	}
	return labelDictionary;
}