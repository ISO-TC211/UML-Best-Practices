!INC Local Scripts.EAConstants-JScript

/**
* Returns whether or not the given connector is an association (including aggregations and compositions) controlled in the same package
* as in the given element.
* This means that, when the package the element belongs to is checked out, both the element and the connector can be changed.
*
* See also section "Add Connectors To Locked Elements" in the EA user guide for the background for the logic in this function.
*
*@author Geodatastyrelsen
*/
function isConnectorAssociationAndControlledInSamePackageAsElement(aConnector /* : EA.Connector */, anElement /* : EA.Element */) /* : boolean */ {
	var result;
	result =
	(Repository.GetElementByID(aConnector.ClientID).PackageID == Repository.GetElementByID(aConnector.SupplierID).PackageID 
		&& (aConnector.Type == "Association" || aConnector.Type == "Aggregation"))
	||
	((aConnector.ClientID == anElement.ElementID && (aConnector.Type == "Association" || (aConnector.Type == "Aggregation" && aConnector.Subtype == "Weak")))
	||
	(aConnector.SupplierID == anElement.ElementID && aConnector.Type == "Aggregation" && aConnector.Subtype == "Strong"));
	return result;
}