!INC Local Scripts.EAConstants-JScript

/*
* Do not use Collection.GetByName for searching for tagged values: documentation "If the collection contains items, but it was unable to 
* find an object with the specified name, the method raises an exception" (note: the exception is Index out of bounds).
*/

function getTaggedValueElement(theElement /* : EA.Element */, taggedValueName /* : String */, defaultValue /* : String */) /* : variant */ {
	var result = defaultValue;
	
	if (theElement != null && taggedValueName.length > 0) {
		var taggedValue as EA.TaggedValue;
		var taggedValues as EA.Collection;
		
		taggedValue = null;
		taggedValues = theElement.TaggedValues;
		
		for (var i = 0; i < taggedValues.Count; i++) {
			if (taggedValues.GetAt(i).Name == taggedValueName) {
				taggedValue = taggedValues.GetAt(i);
				break;
			}
		}
		
		if (taggedValue != null) {
			if (taggedValue.Value == "<memo>") {
				result = taggedValue.Notes;
			} else {
				result = taggedValue.Value;
			}
		}
	}
	
	return result;
}

function setTaggedValueElement(theElement /* : EA.Element */, taggedValueName /* : String */, taggedValueValue /* : variant */) /* : void */ {
	if (theElement != null && taggedValueName.length > 0) {
		var taggedValue as EA.TaggedValue;
		var taggedValues as EA.Collection;
		
		taggedValue = null;
		taggedValues = theElement.TaggedValues;
		
		for (var i = 0; i < taggedValues.Count; i++) {
			if (taggedValues.GetAt(i).Name == taggedValueName) {
				taggedValue = taggedValues.GetAt(i);
				break;
			}
		}
		
		if (taggedValue == null) {
			taggedValue = theElement.TaggedValues.AddNew(taggedValueName, taggedValueValue);
		}
		else {
			if (taggedValue.Value == "<memo>") {
				taggedValue.Notes = taggedValueValue;
			} else {
				validateTaggedValueValue(taggedValueValue);
				taggedValue.Value = taggedValueValue;
			}
		}
		taggedValue.Update();
		theElement.TaggedValues.Refresh();
	}
}

function getTaggedValueAttribute(attribute /* : EA.Attribute */, taggedValueName /* : String */, defaultValue /* : String */) /* : variant */ {
	var result = defaultValue;
	
	if (attribute != null && taggedValueName.length > 0) {
		var taggedValue as EA.AttributeTag;
		var taggedValues as EA.Collection;
		
		taggedValue = null;
		taggedValues = attribute.TaggedValues;
		
		for (var i = 0; i < taggedValues.Count; i++) {
			if (taggedValues.GetAt(i).Name == taggedValueName) {
				taggedValue = taggedValues.GetAt(i);
				break;
			}
		}
				
		if (taggedValue != null) {
			if (taggedValue.Value == "<memo>") {
				result = taggedValue.Notes;
			} else {
				result = taggedValue.Value;
			}
		}
	}
	return result;
}

function setTaggedValueAttribute(attribute , taggedValueName /* : String */, taggedValueValue /* : variant */) /* : void */ {
	if (attribute != null && taggedValueName.length > 0) {
		var taggedValue as EA.AttributeTag;
		var taggedValues as EA.Collection;
		
		taggedValue = null;
		taggedValues = attribute.TaggedValues;

		for (var i = 0; i < taggedValues.Count; i++) {
			if (taggedValues.GetAt(i).Name == taggedValueName) {
				taggedValue = taggedValues.GetAt(i);
				break;
			}
		}
		
		if (taggedValue == null) {
			taggedValue = attribute.TaggedValues.AddNew(taggedValueName, taggedValueValue);
		}
		else {
			if (taggedValue.Value == "<memo>") {
				taggedValue.Notes = taggedValueValue;
			} else {
				validateTaggedValueValue(taggedValueValue);
				taggedValue.Value = taggedValueValue;
			}
		}
		taggedValue.Update();
		attribute.TaggedValues.Refresh();
	}
}

function getTaggedValueConnectorEnd(connector, taggedValueName, source /* : boolean */, defaultValue) {
	var result = defaultValue;
	if (connector != null && taggedValueName.length > 0) {
		var taggedValues as EA.Collection;
		var taggedValue as EA.RoleTag;
		if (source) {
			taggedValues = connector.ClientEnd.TaggedValues;
		} else {
			taggedValues = connector.SupplierEnd.TaggedValues;
		}
		for (var i = 0; i < taggedValues.Count; i++) {
			if (taggedValues.GetAt(i).Tag == taggedValueName) {
				taggedValue = taggedValues.GetAt(i);
				break;
			}
		}
		if (taggedValue != null) {
			if (taggedValue.Value.substr(0, 6) == "<memo>") {
				result = taggedValue.Value.substr(16); // the following is removed from the start of the value: <memo>$ea_notes=
			} else {
				result = taggedValue.Value.split("$ea_notes=")[0];
			}
		}
	}
	return result;
}

function setTaggedValueConnectorEnd(connector, taggedValueName /* : String */, taggedValueValue /* : variant */, source /* : boolean */) /* : void */ {
	if (connector != null && taggedValueName.length > 0) {
		var taggedValues as EA.Collection;
		if (source) {
			taggedValues = connector.ClientEnd.TaggedValues;
		} else {
			taggedValues = connector.SupplierEnd.TaggedValues;
		}
		
		var taggedValue as EA.RoleTag;
		taggedValue = null;
		
		for (var i = 0; i < taggedValues.Count; i++) {
			if (taggedValues.GetAt(i).Tag == taggedValueName) {
				taggedValue = taggedValues.GetAt(i);
				break;
			}
		}
		
		if (taggedValue == null) {
			taggedValue = taggedValues.AddNew(taggedValueName, taggedValueValue);
		}
		else {
			if (taggedValue.Value.substr(0, 6) == "<memo>") {
				taggedValue.Value = "<memo>$ea_notes=" + taggedValueValue;
			} else {
				validateTaggedValueValue(taggedValueValue);
				taggedValue.Value = taggedValueValue;
			}
		}
		taggedValue.Update();
		taggedValues.Refresh();
	}
}

function validateTaggedValueValue(taggedValueValue /* : String */) { /* : void */
	if (taggedValueValue.length > 255) {
		LOGWarning("Tagged value " + taggedValueValue + " contains more than 255 characters and will be truncated");
	}
	if (taggedValueValue.indexOf('\r') != -1 || taggedValueValue.indexOf('\n') != -1) {
		LOGWarning("Tagged value " + taggedValueValue + " contains a newline and will not be set correctly by EA");
	}
}