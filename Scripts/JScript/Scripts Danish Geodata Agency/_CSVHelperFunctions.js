!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-CSV

/**
* Opens a dialog to choose a CSV file and save it.
*
* See also documentation of Project Class, method GetFileNameDialog.
*/
function chooseCSVFileDialog(defaultFileName) {
	var filename, filterString, filterindex, flags, initialDirectory, openOrSave, filepath;

	filename = defaultFileName;
	filterString = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*||";
	filterindex = 1;
	flags = 0x2; //OFN_OVERWRITEPROMPT
	initialDirectory = "";
	openOrSave = 1;
	
	filepath = Repository.GetProjectInterface().GetFileNameDialog(filename, filterString, filterindex, flags, initialDirectory, openOrSave);
	return filepath;
}

/**
* Opens a dialog to open a CSV file.
*
* See also documentation of Project Class, method GetFileNameDialog.
*/
function openCSVFileDialog() {
	var filename, filterString, filterindex, flags, initialDirectory, openOrSave, filepath;

	filename = "";
	filterString = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*||";
	filterindex = 1;
	flags = 0x2; //OFN_OVERWRITEPROMPT
	initialDirectory = "";
	openOrSave = 0;
	
	filepath = Repository.GetProjectInterface().GetFileNameDialog(filename, filterString, filterindex, flags, initialDirectory, openOrSave);
	return filepath;
}

/**
 * Modified from CSVEExportInitialize in EAScriptLib.JScript-CSV
 */
function initializeCSVEExport(columns /* : Array */, 
	exportColumnHeadings /* : boolean */) /* : void */ {
	if (!exportIsExporting) {
		// Switch into exporting mode
		exportIsExporting = true;
		
		// stream: global var
		stream = new ActiveXObject("ADODB.Stream");
		stream.Type = 2 // text data (as apposed to binary data), see also https://msdn.microsoft.com/en-us/library/windows/desktop/ms675277%28v=vs.85%29.aspx
		stream.Charset = "utf-8";
		stream.LineSeparator = -1; // carriage return line feed, see also https://msdn.microsoft.com/en-us/library/windows/desktop/ms675028%28v=vs.85%29.aspx
		stream.Open();
		
		exportColumns = columns;
		
		if (exportColumnHeadings) {
			// Export column headings if the option was enabled
			var headingString = "";
			
			for (var i = 0 ; i < exportColumns.length ; i++) {
				if (i == 0)
					headingString += exportColumns[i];
				else
					headingString += CSV_DELIMITER + exportColumns[i];
			}
			stream.WriteText(headingString, 1);
		}
	}
	else {
		LOGWarning("CSV Export is already in progress");
	}
}

/**
 * Modified from CSVEExportFinalize in EAScriptLib.JScript-CSV
 */
function finalizeCSVEExport(fileName /* : String */) /* : void */
{
	if (exportIsExporting) {
		stream.SaveToFile(fileName, 2);
		// Clean up file object and column array
		stream.Close();
		stream = null;
		exportColumns = null;
		
		// Switch out of exporting mode
		exportIsExporting = false;
	}
	else {
		LOGWarning("CSV Export is not currently in progress");
	}
}

/**
* Modified from CVSExportRow in EAScriptLib.JScript-CSV
*/
function exportCSVRow(valueMap /* : Scripting.Dictionary */) /* : void */
{
	if (exportIsExporting) {
		if (exportColumns.length > 0) {
			// Build a string for the row
			var rowString = "";
			
			// Iterate over all columns specified in CSVEExportInitialize()
			for (var i = 0 ; i < exportColumns.length ; i++) {
				// Get the column name
				var currentColumn = exportColumns[i];
				
				// Get the corresponding field value from valueMap
				var fieldValue = valueMap.Item(currentColumn);
				
				// If the fieldValue is null/undefined, output an empty string enclosed in double-quotes
				if (fieldValue == null) {
					fieldValue = '""';
				}
				
				if (i == 0) {
					rowString += escapeDQuotesAndEncloseInDQuotes(fieldValue);
				}
				else {
					rowString += CSV_DELIMITER + escapeDQuotesAndEncloseInDQuotes(fieldValue);
				}
			}
			
			// Output to file
			stream.WriteText(rowString, 1);
		}
	}
	else {
		LOGWarning("CSV Export is not currently in progress. Call CSVEExportInitialize() to start a CSV Export");
	}
}

/**
* Is meant to replace __CSVEToSafeCSVString from JScript-CSV, since that function strips out delimiters and strips out line breaks,
* which is not always desired.
*
* This function follows the format described in http://tools.ietf.org/html/rfc4180:
* -> Fields containing line breaks (CRLF), double quotes, and commas should be enclosed in double-quotes.
* -> If double-quotes are used to enclose fields, then a double-quote appearing inside a field must be escaped by preceding it with another double quote.
*/
 function escapeDQuotesAndEncloseInDQuotes(originalString) { /* : String */
	var returnString = new String(originalString);
	var regExp = new RegExp('"', "gm"); // g: global search for all occurrences, m: multiline search
	returnString = '"' + returnString.replace(regExp, '""') + '"';
	return returnString;
 }
 
 /**
 * Parses the file given in fileName (retrieve the fileName e.g. with function openCSVFileDialog()).
 *
 * ADODB.Stream is used instead of Scripting.FileSystemObject because the latter one does not support
 * UTF-8.
 */
 function parseCSVFile(fileName) { /* 2-dimensional array */
	LOGInfo("Parsing file " + fileName);
	var stream = new ActiveXObject("ADODB.Stream");
	stream.Type = 2 // text data (as apposed to binary data), see also https://msdn.microsoft.com/en-us/library/windows/desktop/ms675277%28v=vs.85%29.aspx
	stream.Charset = "utf-8";
	stream.Open();
	stream.LoadFromFile(fileName);
	var contents = stream.ReadText();
	stream.Close();
	var parsedContents = parseCSV(contents);
	return parsedContents;
}

/**
* Simple CSV parse function that handles quoted fields containing the field delimiter, new lines, and escaped double
* quotation marks.
* 
* Modified from http://stackoverflow.com/a/14991797/655063 :
* -> syntax for character at a certain position in a string: str[c] vs. str.charAt(c)
* -> added support for new lines in Windows EOL format vs. Unix and Mac OS X EOL format
*/
function parseCSV(str) { /* 2-dimensional array */
    var arr = [];
    var quote = false;  // true means we're inside a quoted field

    // iterate over each character, keep track of current row and column (of the returned array)
    for (var row = col = c = 0; c < str.length; c++) {
        var cc = str.charAt(c), nc = str.charAt(c+1);  // current character, next character
        arr[row] = arr[row] || [];             // create a new row if necessary
        arr[row][col] = arr[row][col] || '';   // create a new column (start with empty string) if necessary

        // If the current character is a quotation mark, and we're inside a
        // quoted field, and the next character is also a quotation mark,
        // add a quotation mark to the current column and skip the next character
        if (cc == '"' && quote && nc == '"') { arr[row][col] += cc; ++c; continue; }  

        // If it's just one quotation mark, begin/end quoted field
        if (cc == '"') { quote = !quote; continue; }

        // If it's the field delimiter and we're not in a quoted field, move on to the next column
        if (cc == CSV_DELIMITER && !quote) { ++col; continue; }

        // If it's a carriage return followed by a line feed (indicates Windows EOL format) and we're not in a quoted field,
		// move on to the next row, move to column 0 of that new row and skip the next character (which is a line feed)
		if (cc == '\r' && nc == '\n' && !quote) { ++row; col = 0; ++c; continue; }
		// If it's a line feed (indicates Unix and Mac OS X EOL format; if it was Windows EOL format then it was already handled by
		// the previous line) and we're not in a quoted field, move on to the next row and move to column 0 of that new row
		if (cc == '\n' && !quote) { ++row; col = 0; continue; }

        // Otherwise, append the current character to the current column
        arr[row][col] += cc;
    }
    return arr;
}