This folder contains scripts developed at the [Danish Geodata Agency](http://eng.gst.dk/) for automated maintenance and validation of models.

Note that slighty different UML profile is used: 
* stereotypes have Danish names
* Enumeration and DataType metaclasses are extended for enumerations and datatypes, not the Class metaclass (see also [UML issues](https://github.com/ISO-TC211/UML-Best-Practices/blob/master/Reference%20material/UML%20issues.pdf))
* documentation (definition, note, alternative name, example and legislative basis) is kept in tagged values, not in the Notes

The scripts are organised in different categories:
* CHG: scripts that change the model
* DOC scripts that produce documentation of the model
* INFO scripts that show information about the eap-file or related stuff
* VAL scripts that validate models
* scripts that start with an underscore should not/cannot be run directly