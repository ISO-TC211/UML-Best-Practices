!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-XML
!INC EAScriptLib.JScript-Logging

var LOGLEVEL_INFO = 2;
var LOGLEVEL_WARNING = 1;
var LOGLEVEL = LOGLEVEL_INFO;

/**
 * Saves all the scripts belonging to the given script group in the given folder (input given via a dialog).
 *
 * This folder is created when it does not yet exist. An error is thrown when the folder name is invalid or not enough permissions are present.
 *
 * @author Geodatastyrelsen
 */
function main() {
	Repository.EnsureOutputVisible("Script");
	
	var scriptGroupName = Session.Input("Name of the script group that should be saved:");
	if (scriptGroupName.length == 0) {
		LOGError("No script group given");
		return;
	}
	var scriptFolderPath = Session.Input("Folder where the scripts should be saved:");
	if (scriptFolderPath.length == 0) {
		LOGError("No script group given");
		return;
	}
	validateAndCreateScriptFolderPathIfNeeded(scriptFolderPath);
	
	// See book "Inside Enterprise Architect", section 6.5 User Defined Scripts: t_script for more information about this query
	var XMLFormattedString = Repository.SQLQuery("select s2.notes as script_metadata, s2.script as script_contents from t_script s1 inner join t_script s2 on s1.scriptname = s2.scriptauthor where s1.script = '" + scriptGroupName + "'");
	/* 
	See https://msdn.microsoft.com/en-us/library/ms764730%28v=vs.85%29.aspx for more information about XML handling through DOM
	in Microsoft XML Core Services (MSXML).
	*/
	var xmlDOM = XMLParseXML(XMLFormattedString); // ActiveXObject("MSXML2.DOMDocument")
	if (xmlDOM == null) {
		LOGError("Query did not return valid XML, or the XML could not be parsed.");
		return;
	}	
	var rowNodes = xmlDOM.selectNodes("//Row"); // MSXML2.IXMLDOMNodeList
	LOGInfo("Number of scripts in script group " + scriptGroupName + ": " + rowNodes.length);
	var rowNode;
	for (var i = 0; i < rowNodes.length; i++) {
		rowNode = rowNodes.item(i);
		var scriptFileName = determineScriptFileName(rowNode);
		var scriptFileContents = retrieveScriptContents(rowNode);
		var scriptPath = scriptFolderPath + "\\" + scriptFileName;
		writeScriptFile(scriptPath, scriptFileContents);
		LOGInfo(scriptPath + " written.");
	}
	LOGInfo("Done!");
}

function validateAndCreateScriptFolderPathIfNeeded(scriptFolderPath /* String */) {
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	if (fso.FolderExists(scriptFolderPath)) {
		LOGInfo("Folder " + scriptFolderPath + " exists.");
	} else {
		fso.CreateFolder(scriptFolderPath);
		LOGInfo("Folder " + scriptFolderPath + " created.");
	}
}

/**
 * rowNode contains
 * <Row><script_metadata>...</script_metadata><script_contents>...</script_contents></Row>
 */
function determineScriptFileName(rowNode /* MSXML2.IXMLDOMNode */) { /* : String */
	var metadataNode = rowNode.selectSingleNode("./script_metadata");
	// variable metadataDOM is the DOM representation of <Script Name="<name>" Type="Internal" Language="<lang>"/>
	var metadataDOM = XMLParseXML(metadataNode.text);
	var scriptName = metadataDOM.selectSingleNode("./Script/@Name").nodeValue;
	var scriptLanguage = metadataDOM.selectSingleNode("./Script/@Language").nodeValue;
	var scriptExtension;
	switch (scriptLanguage) {
		case "JScript":
		case "JavaScript":
			scriptExtension = ".js";
			break;
		case "VBScript":
			scriptExtension = ".vbs";
			break;
		default:
			LOGError("Unknown script language " + scriptLanguage);
			scriptExtension = "";
	}
	return scriptName + scriptExtension;
}

/**
 * rowNode contains
 * <Row><script_metadata>...</script_metadata><script_contents>...</script_contents></Row>
 */
function retrieveScriptContents(rowNode /* MSXML2.IXMLDOMNode */) { /* : String */
	var scriptContents = rowNode.selectSingleNode("./script_contents").text;
	var regExp = new RegExp('\n', "gm"); // g: global search for all occurrences, m: multiline search
	// replace new line with carriage return + new line, in order to match the encoding of the scripts when saved as files through EA's GUI in Windows
	scriptContents = scriptContents.replace(regExp, '\r\n');
	return scriptContents;
	
}

function writeScriptFile(scriptFilePath /* String */, scriptFileContents /* String */) {
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var textStream = fso.OpenTextFile(scriptFilePath, 2, true);
	textStream.Write(scriptFileContents);
	textStream.Close();
}

main();