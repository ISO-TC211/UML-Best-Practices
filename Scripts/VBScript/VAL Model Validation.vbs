option explicit 
 
 !INC Local Scripts.EAConstants-VBScript 
 
' Script Name: Model validation 
' Author: Section for standardization and technology development - Norwegian Mapping Authority

' Version: 1.0

' Date: 2017-05-24


' Purpose: Validate model elements according to rules defined in ISO19103:2015 & ISO19109:2015
'
' Implemented rules: 
'	[ISO19103:2015 Requirement 3]:  
'			Find elements (classes, attributes, navigable association roles, operations, datatypes)  
'	        without definition (notes/rolenotes) in the selected package and subpackages.
'			It is not fully implemented: In this version the requirement for sufficient definition for associations 
'			is fulfilled if association roles at navigable association ends have a definition. 
'			Not implemented yet: Association without definition at all (neither for roles nor for the association) 
'			won't be detected.
'
'	[ISO19103:2015 Requirement 6]: 
'			NCNames in codelist codes.
' 	[ISO19103:2015 requirement 7]:	    
'			Iso 19103 Requirement 7 - definition of codelist codes.
'  	[ISO19103:2015 Requirement 10]: 
'			Check if all navigable association ends have cardinality 
'	[ISO19103:2015 Requirement 11]: 
'			Check if all navigable association ends have role names 
'	[ISO19103:2015 Requirement 12]: 
'			If datatypes have associations then the datatype shall only be target in a composition 
'  	[ISO19103:2015 Requirement 14]:
'			Checks that there is no inheritance between classes with unequal stereotypes.
'	[ISO19103:2015 Requirement 15]:
'			check for known stereotypes
'  	[ISO19103:2015 requirement 16]:
'			Iso 19103 Requirement 16 - legal NCNames case-insesnitively unique within their namespace
'  	[ISO19103:2015 Requirement 18]:
'			checks that all elements show all structures in at least one diagram
'			Tests all classes and their attributes in diagrams including roles and inheritance.
'	[ISO19103:2015 Requirement 19]:
'			All classes shall have a definition describing its intended meaning or semantics.
'   [ISO19103:2015 Recommendation 1]:
'			Checks every initial values in codeLists and enumerations for a package. If one or more initial values are numeric in one list, 
' 			it return a warning message. 
'	[ISO19103:2015 Recommendation 4]:
' 			for external codelists with a taggedValue "codeList" the value must not be empty
'	[ISO19103:2015 recommendation 11]:
'			Check if names of attributes, operations, roles start with lower case and names of packages,  
'			classes and associations start with upper case 
'	[ISO19103:2015 Requirement 25]   
'			check for valid extended types for attributes (URI etc.), builds on iso 19103 Requirement 22.
'	[ISO19103:2015 Requirement 22]    
'			from iso 19103 - check for valid core types for attributes (CharacterString etc.).
'	[ISO19109:2015 /req/uml/documentation]: 
'			Same as [ISO19103:2015 Requirement 3] but checks also for definitions of constraints
'			The part that checks definitions of constraints is implemented in sub checkConstraint	
'			The rest is implemented in sub checkDefinitions
'   [ISO19109:2015 /req/multi-lingual/feature]:
' 			if tagged value: "designation", "description" or "definition" exists, the value of the tag must end with "@<language-code>". 
' 			Checks FeatureType and PropertyType (attributes, operations, roles) 
'	[ISO19109:2015 /req/multi-lingual/package]:
'			Check if the ApplicationSchema-package got a tagged value named "language" (error message if that is not the case) 
'			and if the value of it is empty or not (error message if empty). 
' 			And if there are designation-tags, checks that they have correct structure: "{name}"@{language}
' 	
'	[ISO19109:2015 /req/uml/constraint]
'			To check if a constraint lacks name or definition. 
'  	[ISO19109:2015 /req/uml/packaging]:
'			ApplicationSchema shall be described within a package carrying stereotype ApplicationSchema
'     		To check if the value of the version-tag (tagged values) for an ApplicationSchema-package is empty or not. 
'	[ISO19109:2015 /req/uml/structure]
'			Check that all abstract classes in application schema has at least one instantiable subclass within the same schema.  Check that no classes in application schema has stereotype interface

'	[ISO19109:2015 /req/uml/profile]    
'			check for valid well known types for all attributes (GM_Surface etc.), builds on iso 19103 Requirement 22 and 25.

'	[ISO19109:2015 /req/uml/feature]
'			featureType classes shall have unique names within the applicationSchema	
'			Not implemented yet: instances of FeatureType shall have generalization with AnyFeature
'	[ISO19109:2015 /req/general/feature]
' 			Checks that no «FeatureTypes» inherits from a class named GM_Object or TM_object. 
'			Check that FeatureTypes within a ApplicationSchema have unique names (triggers in the sub 'checkUniqueFeatureTypeNames').
'
'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Project Browser Script main function 
 
 sub OnProjectBrowserScript() 
 	 
	Repository.EnsureOutputVisible("Script")
 	' Get the type of element selected in the Project Browser 
 	dim treeSelectedType 
 	treeSelectedType = Repository.GetTreeSelectedItemType() 
 	 
 	' Handling Code: Uncomment any types you wish this script to support 
 	' NOTE: You can toggle comments on multiple lines that are currently 
 	' selected with [CTRL]+[SHIFT]+[C]. 
 	select case treeSelectedType 
 	 
 '		case otElement 
 '			' Code for when an element is selected 
 '			dim theElement as EA.Element 
 '			set theElement = Repository.GetTreeSelectedObject() 
 '					 
 		case otPackage 
 			' Code for when a package is selected 
 			dim thePackage as EA.Package 
 			set thePackage = Repository.GetTreeSelectedObject() 
 			
			'the selected package must not be a root package (="model" package) in the project browser 
			if not thePackage.IsModel then
				'check if the selected package has stereotype applicationSchema 
 			
				'if UCase(thePackage.element.stereotype) = UCase("applicationSchema") then 
				
					dim box, mess
					'mess = 	"Model validation 2016-08-19 Logging errors and warnings."&Chr(13)&Chr(10)
					mess = "Model validation based on requirements and recommendations in ISO 19103:2015 and ISO 19109:2015"&Chr(13)&Chr(10)
					mess = mess + ""&Chr(13)&Chr(10)
					mess = mess + "Please find a list with the implemented rules in this script's source code (line 15++)."&Chr(13)&Chr(10)
					mess = mess + ""&Chr(13)&Chr(10)
					mess = mess + "Starting model validation for package [" & thePackage.Name &"]."&Chr(13)&Chr(10)

					box = Msgbox (mess, vbOKCancel, "Model validation 1.0")
					select case box
						case vbOK
							'inputBoxGUI to receive user input regarding rule set 19109 or 19103
							dim ruleSetFromInputBox, ruleSetInputBoxText, correctInputRuleSet, abortRuleSet
							dim defaultRuleSet, wrongRuleSet
							
							'set boolean variable wrongRuleSet to false (default)
							'this is used to identify wrong combination of 19109 rules and packages without applicationSchema stereotype
							wrongRuleSet = false
							
							'default rule set is 3 (= 19103)
							defaultRuleSet = "3"
							if (UCase(thePackage.element.stereotype) = UCase("applicationSchema")) then
								'if a package with stereotype applicationSchema is selected, default rule set is 9 (= 19109)
								defaultRuleSet = "9"
							end if
							
							ruleSetInputBoxText = "Please select the rule set."&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ ""&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ ""&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ "3 - ISO 19103:2015 rules."&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ ""&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ "9 - ISO 19109:2015 rules (includes ISO 19103 rules)."&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ ""&Chr(13)&Chr(10)
							ruleSetInputBoxText = ruleSetInputBoxText+ "Enter 3 or 9:"&Chr(13)&Chr(10)
							correctInputRuleSet = false
							abortRuleSet = false
							
							'todo1: default = 9 if applicationSchema-package is choosen and 3 if non-aplicationSchema is choosen
							'todo2: exit already after first InputBox if 19109 is selected for non-appSchema NB: ok tu run 19103 ruleset on applicationschema
							
							do while not correctInputRuleSet
						
								ruleSetFromInputBox = InputBox(ruleSetInputBoxText, "Select rule set", defaultRuleSet)
								select case true 
									case UCase(ruleSetFromInputBox) = "3"	
										'code for when 3 = 19103 rule set has been selected
										globalRuleSet19109 = false
										correctInputRuleSet = true
									case UCase(ruleSetFromInputBox) = "9"	
										'code for when 9 = 19109 rule set has been selected
										globalRuleSet19109 = true
										correctInputRuleSet = true
										if not (UCase(thePackage.element.stereotype) = UCase("applicationSchema")) then
											wrongRuleSet = true
										end if
									case IsEmpty(ruleSetFromInputBox)
										'user pressed cancel or closed the dialog
										MsgBox "Abort",64
										abortRuleSet = true
										exit do
									case else
										MsgBox "You made an incorrect selection! Please enter either '3' or '9'.",48
								end select
							
							loop
							
							
							if not abortRuleSet and not wrongRuleSet then
							
							'inputBoxGUI to receive user input regarding the log level
							dim logLevelFromInputBox, logLevelInputBoxText, correctInputLogLevel, abortLogLevel
							logLevelInputBoxText = "Please select the log level."&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ ""&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ ""&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ "E - Error log level: logs error messages only."&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ ""&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ "W - Warning log level (recommended): logs error and warning messages."&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ ""&Chr(13)&Chr(10)
							logLevelInputBoxText = logLevelInputBoxText+ "Enter E or W:"&Chr(13)&Chr(10)
							correctInputLogLevel = false
							abortLogLevel = false
							do while not correctInputLogLevel
						
								logLevelFromInputBox = InputBox(logLevelInputBoxText, "Select log level", "W")
								select case true 
									case UCase(logLevelFromInputBox) = "E"	
										'code for when E = Error log level has been selected, only Error messages will be shown in the Script Output window
										globalLogLevelIsWarning = false
										correctInputLogLevel = true
									case UCase(logLevelFromInputBox) = "W"	
										'code for when W = Error log level has been selected, both Error and Warning messages will be shown in the Script Output window
										globalLogLevelIsWarning = true
										correctInputLogLevel = true
									case IsEmpty(logLevelFromInputBox)
										'user pressed cancel or closed the dialog
										MsgBox "Abort",64
										abortLogLevel = true
										exit do
									case else
										MsgBox "You made an incorrect selection! Please enter either 'E' or 'W'.",48
								end select
							
							loop
							end if
							
							if wrongRuleSet then
								Msgbox "The selected rule set is ISO 19109 - 'Rules for application schema' but package [" & thePackage.Name &"] does not have stereotype «ApplicationSchema». Please select a package with stereotype «ApplicationSchema» to start model validation with ISO 19109 rule set. [19109:2015 /req/uml/packaging]",48 
							else
							

								if not abortLogLevel and not abortRuleSet then
									Dim StartTime, EndTime, Elapsed
									StartTime = timer 
									
									'give an initial feedback in system output 
									Session.Output("Model validation 1.0 started "&Now())
									dim ruleSetText
									if globalRuleSet19109 then
										ruleSetText = "ISO 19109:2015 (includes ISO 19103 rules)"
									else
										ruleSetText = "ISO 19103:2015"
									end if
									Session.Output("Using rule set: "&ruleSetText)
									
									'Check model for script breaking structures
									if scriptBreakingStructuresInModel(thePackage) then
										Session.Output("Critical Errors: The errors listed above must be corrected before the script can validate the model.")
										Session.Output("Aborting Script.")
										exit sub
									end if

									call populatePackageIDList(thePackage)
									call populateClassifierIDList(thePackage)
									'call findPackageDependencies(thePackage.Element)
									'call getElementIDsOfExternalReferencedElements(thePackage)
									'call findPackagesToBeReferenced()
									'call checkPackageDependency(thePackage)
															             				  
									'For /req/Uml/Profile:
									Set ProfileTypes = CreateObject("System.Collections.ArrayList")
									Set ExtensionTypes = CreateObject("System.Collections.ArrayList")
									Set CoreTypes = CreateObject("System.Collections.ArrayList")
									reqUmlProfileLoad()
									'For requirement 18:
									set startPackage = thePackage
									Set diaoList = CreateObject( "System.Collections.Sortedlist" )
									Set diagList = CreateObject( "System.Collections.Sortedlist" )
									recListDiagramObjects(thePackage)

									startPackageName = thePackage.Name
								
									'choose between 19109 or 19103 rule set
									if globalRuleSet19109 then
										call dependencyLoop(thePackage.Element)
										FindInvalidElementsInPackage19109Rules(thePackage)
									elseif not globalRuleSet19109 then
										FindInvalidElementsInPackage19103Rules(thePackage)
									end if
								
									'------------------------------------------------------------------ 
									'---Check global variables--- 
									'------------------------------------------------------------------ 
								
									if globalRuleSet19109 then						
										'check uniqueness of featureType names according to [ISO19109:2015 /req/uml/feature]
										checkUniqueFeatureTypeNames()
									end if
								
									'final report
									Elapsed = formatnumber((Timer - StartTime),2)
									Session.Output("-----Report for package ["&startPackageName&"]-----") 		
									Session.Output("   Number of errors found: " & globalErrorCounter) 
									if globalLogLevelIsWarning then
										Session.Output("   Number of warnings found: " & globalWarningCounter)
									end if	
									Session.Output("   Run time: " &Elapsed& " seconds" )
								end if	
							end if	
						case VBcancel
							'nothing to do						
					end select 
				'else 
 				'Msgbox "Package [" & thePackage.Name &"] does not have stereotype «ApplicationSchema». Select a package with stereotype «ApplicationSchema» to start model validation." 
				'end if
			else
			Msgbox "Package [" & thePackage.Name &"] is a root package. Please select a non-root package to start model validation.",48
 			end if
 			 
 			 
'		case otDiagram 
'			' Code for when a diagram is selected 
'			dim theDiagram as EA.Diagram 
'			set theDiagram = Repository.GetTreeSelectedObject() 
'			 
'		case otAttribute 
'			' Code for when an attribute is selected 
'			dim theAttribute as EA.Attribute 
'			set theAttribute = Repository.GetTreeSelectedObject() 
'			 
'		case otMethod 
'			' Code for when a method is selected 
'			dim theMethod as EA.Method 
'			set theMethod = Repository.GetTreeSelectedObject() 
 		 
 		case else 
 			' Error message 
 			Msgbox "Please select a package to start model validation.",48
			 			 
 	end select 
 	 
end sub 
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

 
'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'Sub name: 		PopulatePackageIDList
'Author: 		Åsmund Tjora
'Date: 			20170223
'Purpose: 		Populate the globalPackageIDList variable. 
'Parameters:	rootPackage  The package to be added to the list and investigated for subpackages
' 
sub PopulatePackageIDList(rootPackage)
	dim subPackageList as EA.Collection
	dim subPackage as EA.Package
	set subPackageList = rootPackage.Packages
	
	globalPackageIDList.Add(rootPackage.PackageID)
	for each subPackage in subPackageList
		PopulatePackageIDList(subPackage)
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'Sub name: 		PopulateClassifierIDList
'Author: 		Åsmund Tjora
'Date: 			20170228
'Purpose: 		Populate the globalListAllClassifierIDsInApplicationSchema variable. 
'Parameters:	rootPackage  The package to be added to the list and investigated for subpackages

sub PopulateClassifierIDList(rootPackage)
	dim containedElementList as EA.Collection
	dim containedElement as EA.Element
	dim subPackageList as EA.Collection
	dim subPackage as EA.Package
	set containedElementList = rootPackage.Elements
	set subPackageList = rootPackage.Packages
	
	for each containedElement in containedElementList
		globalListAllClassifierIDsInApplicationSchema.Add(containedElement.ElementID)
	next
	for each subPackage in subPackageList
		PopulateClassifierIDList(subPackage)
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'Function name: scriptBreakingStructuresInModel
'Author: 		Åsmund Tjora
'Date: 			20170511 
'Purpose: 		Check that the model does not contain structures that will break script operations (e.g. cause infinite loops)
'Parameter: 	the package where the script runs
'Return value:	false if no script-breaking structures in model are found, true if parts of the model may break the script.
'Sub functions and subs:	inHeritanceLoop, inheritanceLoopCheck
function scriptBreakingStructuresInModel(thePackage)
	dim retVal
	retVal=false
	dim currentElement as EA.Element
	dim elements as EA.Collection
	
	'Package Dependency Loop Check will not break script.  Do not check here.
	set currentElement = thePackage.Element
'	retVal=retVal or dependencyLoop(currentElement)
	
	'Inheritance Loop Check
	set elements = thePackage.elements
	dim i
	for i=0 to elements.Count-1
		set currentElement = elements.GetAt(i)
		if(currentElement.Type="Class") then
			retVal=retVal or inheritanceLoop(currentElement)
		end if
	next
	scriptBreakingStructuresInModel = retVal
end function

'Function name: dependencyLoop
'Author: 		Åsmund Tjora
'Date: 			20170511 
'Purpose: 		Check that dependency structure does not form loops.  Return true if no loops are found, return false if loops are found
'Parameter: 	Package element where check originates
'Return value:	false if no loops are found, true if loops are found.
function dependencyLoop(thePackageElement)
	dim retVal
	dim checkedPackagesList
	set checkedPackagesList = CreateObject("System.Collections.ArrayList")
	retVal=dependencyLoopCheck(thePackageElement, checkedPackagesList)
	if retVal then
		Session.Output("Error:  The dependency structure originating in [«" & thePackageElement.StereoType & "» " & thePackageElement.name & "] contains dependency loops [ISO19109:2015 /req/uml/integration]")
		Session.Output("          See the list above for the packages that are part of a loop.")
		Session.Output("          Ignore this error for dependencies between packages outside the control of the current project.")
		globalErrorCounter = globalErrorCounter+1
	end if
	dependencyLoop = retVal
end function

function dependencyLoopCheck(thePackageElement, dependantCheckedPackagesList)
	dim retVal
	dim localRetVal
	dim dependee as EA.Element
	dim connector as EA.Connector
	
	' Generate a copy of the input list.  
	' The operations done on the list should not be visible by the dependant in order to avoid false positive when there are common dependees.
	dim checkedPackagesList
	set checkedPackagesList = CreateObject("System.Collections.ArrayList")
	dim ElementID
	for each ElementID in dependantCheckedPackagesList
		checkedPackagesList.Add(ElementID)
	next
	
	retVal=false
	checkedPackagesList.Add(thePackageElement.ElementID)
	for each connector in thePackageElement.Connectors
		localRetVal=false
		if connector.Type="Usage" or connector.Type="Package" or connector.Type="Dependency" then
			if thePackageElement.ElementID = connector.ClientID then
				set dependee = Repository.GetElementByID(connector.SupplierID)
				dim checkedPackageID
				for each checkedPackageID in checkedPackagesList
					if checkedPackageID = dependee.ElementID then localRetVal=true
				next
				if localRetVal then 
					Session.Output("         Package [«" & dependee.Stereotype & "» " & dependee.Name & "] is part of a dependency loop")
				else
					localRetVal=dependencyLoopCheck(dependee, checkedPackagesList)
				end if
				retVal=retVal or localRetVal
			end if
		end if
	next
	
	dependencyLoopCheck=retVal
end function


'Function name: inheritanceLoop
'Author: 		Åsmund Tjora
'Date: 			20170221 
'Purpose: 		Check that inheritance structure does not form loops.  Return true if no loops are found, return false if loops are found
'Parameter: 	Class element where check originates
'Return value:	false if no loops are found, true if loops are found.
function inheritanceLoop(theClass)
	dim retVal
	dim checkedClassesList
	set checkedClassesList = CreateObject("System.Collections.ArrayList")
	retVal=inheritanceLoopCheck(theClass, checkedClassesList)	
	if retVal then
		Session.Output("Error: Class hierarchy originating in [«" & theClass.Stereotype & "» "& theClass.Name & "] contains inheritance loops.")
	end if
	inheritanceLoop = retVal
end function

'Function name:	inheritanceLoopCheck
'Author:		Åsmund Tjora
'Date:			20170221
'Purpose		Internal workings of function inhertianceLoop.  Register the class ID, compare list of ID's with superclass ID, recursively call itself for superclass.  
'				Return "true" if class already has been registered (i.e. is a superclass of itself) 

function inheritanceLoopCheck(theClass, subCheckedClassesList)
	dim retVal
	dim superClass as EA.Element
	dim connector as EA.Connector

	' Generate a copy of the input list.  
	'The operations done on the list should not be visible by the subclass in order to avoid false positive at multiple inheritance
	dim checkedClassesList
	set checkedClassesList = CreateObject("System.Collections.ArrayList")
	dim ElementID
	for each ElementID in subCheckedClassesList
		checkedClassesList.Add(ElementID)
	next

	retVal=false
	checkedClassesList.Add(theClass.ElementID)	
	for each connector in theClass.Connectors
		if connector.Type = "Generalization" then
			if theClass.ElementID = connector.ClientID then
				set superClass = Repository.GetElementByID(connector.SupplierID)
				dim checkedClassID
				for each checkedClassID in checkedClassesList
					if checkedClassID = superClass.ElementID then retVal = true
				next
				if retVal then 
					Session.Output("Error: Class [«" & superClass.Stereotype & "» " & superClass.Name & "] is a generalization of itself")
				else
					retVal=inheritanceLoopCheck(superClass, checkedClassesList)
				end if
			end if
		end if
	next
	
	inheritanceLoopCheck = retVal
end function

'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'Sub name: 		CheckDefinition
'Author: 		Magnus Karge (minor contribution by Tore Johnsen)
'Date: 			20160925 
'Purpose: 		Check if the provided argument for input parameter theObject fulfills the requirements in [ISO19103:2015 Requirement 3]: 
'				Find elements (classes, attributes, navigable association roles, operations, datatypes)  
'				without definition (notes/rolenotes) 
'				[ISO19103:2015 Requirement 19]:
'				All classes shall have a definition
'@param[in] 	theObject (EA.ObjectType) The object to check,  
'				supposed to be one of the following types: EA.Attribute, EA.Method, EA.Connector, EA.Element 
 
 sub CheckDefinition(theObject) 
 	'Declare local variables 
 	Dim currentAttribute as EA.Attribute 
 	Dim currentMethod as EA.Method 
 	Dim currentConnector as EA.Connector 
 	Dim currentElement as EA.Element 
	Dim currentPackage as EA.Package
 		 
 	Select Case theObject.ObjectType 
 		Case otElement 
 			' Code for when the function's parameter is an element 
 			set currentElement = theObject 
 			 
 			If currentElement.Notes = "" then 
 				if globalRuleSet19109 then
					Session.Output("Error: Class [«" &getStereotypeOfClass(currentElement)& "» "& currentElement.Name & "] has no definition. [ISO19103:2015 Requirement 3], [ISO19109:2015 /req/uml/documentation] & [ISO19103:2015 Requirement 19]")	 
 				elseif not globalRuleSet19109 then
					Session.Output("Error: Class [«" &getStereotypeOfClass(currentElement)& "» "& currentElement.Name & "] has no definition. [ISO19103:2015 Requirement 3] & [ISO19103:2015 Requirement 19]")	 
				end if
				globalErrorCounter = globalErrorCounter + 1 
 			end if 
 		Case otAttribute 
 			' Code for when the function's parameter is an attribute 
 			 
 			set currentAttribute = theObject 
 			 
 			'get the attribute's parent element 
 			dim attributeParentElement as EA.Element 
 			set attributeParentElement = Repository.GetElementByID(currentAttribute.ParentID) 
 			
			if Ucase(attributeParentElement.Stereotype) <> "CODELIST" then
				if Ucase(attributeParentElement.Stereotype) <> "ENUMERATION" then		
					if attributeParentElement.Type <> "Enumeration" then	
						if currentAttribute.Notes = "" then 
							if globalRuleSet19109 then
								Session.Output( "Error: Class [«" &getStereotypeOfClass(attributeParentElement)& "» "& attributeParentElement.Name &"] \ attribute [" & currentAttribute.Name & "] has no definition. [ISO19103:2015 Requirement 3] & [ISO19109:2015 /req/uml/documentation]") 
							elseif not globalRuleSet19109 then
								Session.Output( "Error: Class [«" &getStereotypeOfClass(attributeParentElement)& "» "& attributeParentElement.Name &"] \ attribute [" & currentAttribute.Name & "] has no definition. [ISO19103:2015 Requirement 3]") 
							end if
							globalErrorCounter = globalErrorCounter + 1 
						end if
					end if
				end if
			end if
 			 
 		Case otMethod 
 			' Code for when the function's parameter is a method 
 			 
 			set currentMethod = theObject 
 			 
 			'get the method's parent element, which is the class the method is part of 
 			dim methodParentElement as EA.Element 
 			set methodParentElement = Repository.GetElementByID(currentMethod.ParentID) 
 			 
 			if currentMethod.Notes = "" then 
 				if globalRuleSet19109 then
					Session.Output( "Error: Class [«" &getStereotypeOfClass(methodParentElement)& "» "& methodParentElement.Name &"] \ operation [" & currentMethod.Name & "] has no definition. [ISO19103:2015 Requirement 3] & [ISO19109:2015 /req/uml/documentation]") 
 				elseif not globalRuleSet19109 then
					Session.Output( "Error: Class [«" &getStereotypeOfClass(methodParentElement)& "» "& methodParentElement.Name &"] \ operation [" & currentMethod.Name & "] has no definition. [ISO19103:2015 Requirement 3]") 
				end if
				globalErrorCounter = globalErrorCounter + 1 
 			end if 
 		Case otConnector 
 			' Code for when the function's parameter is a connector 
 			 
 			set currentConnector = theObject 
 			 
 			'get the necessary connector attributes 
 			dim sourceEndElementID 
 			sourceEndElementID = currentConnector.ClientID 'id of the element on the source end of the connector 
 			dim sourceEndNavigable  
 			sourceEndNavigable = currentConnector.ClientEnd.Navigable 'navigability on the source end of the connector 
 			dim sourceEndName 
 			sourceEndName = currentConnector.ClientEnd.Role 'role name on the source end of the connector 
 			dim sourceEndDefinition 
 			sourceEndDefinition = currentConnector.ClientEnd.RoleNote 'role definition on the source end of the connector 
 								 
 			dim targetEndNavigable  
 			targetEndNavigable = currentConnector.SupplierEnd.Navigable 'navigability on the target end of the connector 
 			dim targetEndName 
 			targetEndName = currentConnector.SupplierEnd.Role 'role name on the target end of the connector 
 			dim targetEndDefinition 
 			targetEndDefinition = currentConnector.SupplierEnd.RoleNote 'role definition on the target end of the connector 
 
 
 			dim sourceEndElement as EA.Element 
 			 
 			if sourceEndNavigable = "Navigable" and sourceEndDefinition = "" and currentConnector.Type <> "Dependency" then
 				'get the element on the source end of the connector 
 				set sourceEndElement = Repository.GetElementByID(sourceEndElementID) 
 				if globalRuleSet19109 then
					Session.Output( "Error: Class [«" &getStereotypeOfClass(sourceEndElement)& "» "& sourceEndElement.Name &"] \ association role [" & sourceEndName & "] has no definition. [ISO19103:2015 Requirement 3] & [ISO19109:2015 /req/uml/documentation]") 
 				elseif not globalRuleSet19109 then
					Session.Output( "Error: Class [«" &getStereotypeOfClass(sourceEndElement)& "» "& sourceEndElement.Name &"] \ association role [" & sourceEndName & "] has no definition. [ISO19103:2015 Requirement 3]") 
				end if
				globalErrorCounter = globalErrorCounter + 1 
 			end if 
 			 
 			if targetEndNavigable = "Navigable" and targetEndDefinition = "" and currentConnector.Type <> "Dependency" then
 				'get the element on the source end of the connector (also source end element here because error message is related to the element on the source end of the connector) 
 				set sourceEndElement = Repository.GetElementByID(sourceEndElementID) 
 				if globalRuleSet19109 then 
					Session.Output( "Error: Class [«"&getStereotypeOfClass(sourceEndElement)&"» "&sourceEndElement.Name &"] \ association role [" & targetEndName & "] has no definition. [ISO19103:2015 Requirement 3] & [ISO19109:2015 /req/uml/documentation]") 
 				elseif not globalRuleSet19109 then
					Session.Output( "Error: Class [«"&getStereotypeOfClass(sourceEndElement)&"» "&sourceEndElement.Name &"] \ association role [" & targetEndName & "] has no definition. [ISO19103:2015 Requirement 3]") 
				end if
				globalErrorCounter = globalErrorCounter + 1 
 			end if 
 		Case otPackage 
 			' Code for when the function's parameter is a package 
 			 
 			set currentPackage = theObject 
 			
				
 		Case else		 
 			'TODO: need some type of exception handling here
			Session.Output( "Debug: Function [CheckDefinition] started with invalid parameter.") 
 	End Select 
 	 
end sub 
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'Purpose: 		help function in order to set stereotype that is shown 
'				in diagrams but not accessible as such via EAObjectAPI
'Used in sub: 	checkElementName
'@param[in]: theClass (EA.Element)
'returns: theClass's visible stereotype as character string, empty string if nothing found
 function getStereotypeOfClass(theClass)
	dim visibleStereotype
	visibleStereotype = ""
	if (Ucase(theClass.Stereotype) = Ucase("featuretype")) OR (Ucase(theClass.Stereotype) = Ucase("codelist")) OR (Ucase(theClass.Stereotype) = Ucase("datatype")) OR (Ucase(theClass.Stereotype) = Ucase("enumeration")) then
		'param theClass is Classifier subtype Class with different stereotypes
		visibleStereotype = theClass.Stereotype
	elseif (Ucase(theClass.Type) = Ucase("enumeration")) OR (Ucase(theClass.Type) = Ucase("datatype"))  then
		'param theClass is Classifier subtype DataType or Enumeration
		visibleStereotype = theClass.Type
	end if
	getStereotypeOfClass=visibleStereotype
 end function
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------
 
 
'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub name: checkElementName
' Author: Magnus Karge
' Date: 20160925 
' Purpose:  sub procedure to check if a given element's name is written correctly
' 			Implementation of 19103:2015 recommendation 11
' 			
' @param[in]: theElement (EA.Element). The element to check. Can be class, enumeration, data type, attribute, operation, association, role or package
 
sub checkElementName(theElement) 
	if globalLogLevelIsWarning then
	
		select case theElement.ObjectType
			case otPackage
				'sub parameter is ObjectType oTPackage, check if first letter of the package's name is a capital letter 
				if not Left(theElement.Name,1) = UCase(Left(theElement.Name,1)) then 
					Session.Output("Warning: Package name [" & theElement.Name & "] should start with capital letter. [ISO19103:2015 Recommendation 11]") 
					globalWarningCounter = globalWarningCounter + 1 
				end if
			case otElement
				'sub's parameter is ObjectType oTElement, check if first letter of the element's name is a capital letter (element covers class, enumeration, datatype)
				if not Left(theElement.Name,1) = UCase(Left(theElement.Name,1)) then 
					Session.Output("Warning: Class name [«"&getStereotypeOfClass(theElement)&"» "& theElement.Name & "] should start with capital letter. [ISO19103:2015 Recommendation 11]") 
					globalWarningCounter = globalWarningCounter + 1 
				end if 
			case otAttribute
				'sub's parameter is ObjectType oTAttribute, check if first letter of the attribute's name is NOT a capital letter 
				if not Left(theElement.Name,1) = LCase(Left(theElement.Name,1)) then 
					dim attributeParentElement as EA.Element
					set attributeParentElement = Repository.GetElementByID(theElement.ParentID)
					Session.Output("Warning: Attribute name [" & theElement.Name & "] in class [«"&getStereotypeOfClass(attributeParentElement)&"» "& attributeParentElement.Name &"] should start with lowercase letter. [ISO19103:2015 Recommendation 11]") 
					globalWarningCounter = globalWarningCounter + 1
				end if									
			case otConnector
				dim connector as EA.Connector
				set connector = theElement
				'sub's parameter is ObjectType oTConnector, check if the association has a name (not necessarily the case), if so check if the name starts with a capital letter 
				if not (connector.Name = "" OR len(connector.Name)=0) and not Left(connector.Name,1) = UCase(Left(connector.Name,1)) then 
					dim associationSourceElement as EA.Element
					dim associationTargetElement as EA.Element
					set associationSourceElement = Repository.GetElementByID(connector.ClientID)
					set associationTargetElement = Repository.GetElementByID(connector.SupplierID)
					Session.Output("Warning: Association name [" & connector.Name & "] between class [«"&getStereotypeOfClass(associationSourceElement)&"» "& associationSourceElement.Name &"] and class [«"&getStereotypeOfClass(associationTargetElement)&"» " & associationTargetElement.Name & "] should start with capital letter. [ISO19103:2015 Recommendation 11]") 
					globalWarningCounter = globalWarningCounter + 1 
				end if 
			'case otOperation
			'case otRole
		end select	
	end if
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Script Name: checkTVLanguageAndDesignation
' Author: Sara Henriksen (original version), Åsmund Tjora
' Date: 26.07.16 (original version), 20.01.17 (release 1.1), 02.02.17
' Purpose: Check if the ApplicationSchema-package got a tag named "language" and  check if the value is empty or not. 
' Check that designation tags have correct structure: "{name}"@{language}, and that there is at least one English ("{name}"@en) designation for ApplicationSchema packages
' Check that definition tags have correct structure: "{name}"@{language}, and that there is at least one English ("{name}"@en) definition for ApplicationSchema packages
	
' sub procedure to check if the package has the provided tags with a value with correct structure
' @param[in]: theElement (Package Class) and taggedValueName (String)

sub checkTVLanguageAndDesignation(theElement, taggedValueName)

	if taggedValueName = "language" then 
 		if UCase(theElement.Stereotype) = UCase("applicationSchema") then
		
			dim packageTaggedValues as EA.Collection 
 			set packageTaggedValues = theElement.TaggedValues 

 			dim taggedValueLanguageMissing 
 			taggedValueLanguageMissing = true 
			'iterate trough the tagged values 
 			dim packageTaggedValuesCounter 
 			for packageTaggedValuesCounter = 0 to packageTaggedValues.Count - 1 
 				dim currentTaggedValue as EA.TaggedValue 
 				set currentTaggedValue = packageTaggedValues.GetAt(packageTaggedValuesCounter) 

				'check if the provided tagged value exist
				if (currentTaggedValue.Name = "language") and not (currentTaggedValue.Value= "") then 

					taggedValueLanguageMissing = false 
					exit for 
				end if   
				if currentTaggedValue.Name = "language" and currentTaggedValue.Value= "" then 
					Session.Output("Error: Package [«"&theElement.Stereotype&"» " &theElement.Name&"] tag ["& currentTaggedValue.Name &"] lacks a value. [ISO19109:2015 /req/multi-lingual/package]") 
					globalErrorCounter = globalErrorCounter + 1 
					taggedValueLanguageMissing = false 
					exit for 
				end if 
 			next 
			if taggedValueLanguageMissing then 
				Session.Output("Error: Package [«"&theElement.Stereotype&"» " &theElement.Name&"] lacks a [language] tag. [ISO19109:2015 /req/multi-lingual/package]") 
				globalErrorCounter = globalErrorCounter + 1 
			end if 
		end if 
	end if 

	if taggedValueName = "designation" then 'or taggedValueName ="definition" 

		if not theElement is nothing and Len(taggedValueName) > 0 then
		
			'check if the element has a tagged value with the provided name
			dim currentExistingTaggedValue1 AS EA.TaggedValue 
			dim valueExists
			dim enDesignation
			dim checkQuoteMark
			dim checkAtMark
			dim taggedValuesCounter1
			valueExists=false
			enDesignation = false
			for taggedValuesCounter1 = 0 to theElement.TaggedValues.Count - 1
				set currentExistingTaggedValue1 = theElement.TaggedValues.GetAt(taggedValuesCounter1)

				'check if the tagged value exists, and checks if the value starts with " and ends with "@{language}, if not, return an error. 
				if currentExistingTaggedValue1.Name = taggedValueName then
					valueExists=true
					checkQuoteMark=false
					checkAtMark=false
					
					if not len(currentExistingTaggedValue1.Value) = 0 then 

						if (InStr(currentExistingTaggedValue1.Value, "@en")<>0) then 
							enDesignation=true
						end if
						
						if (mid(currentExistingTaggedValue1.Value, 1, 1) = """") then 
							checkQuoteMark=true
						end if
						if (InStr(currentExistingTaggedValue1.value, """@")<>0) then 
							checkAtMark=true
						end if
						
						if not (checkAtMark and checkQuoteMark) then
							Session.Output("Error: Package [«" &theElement.Stereotype& "» " &theElement.Name&"] tag [" &taggedValueName& "] has an illegal value.  Expected value ""{" &taggedValueName& "}""@{language code} [ISO19109:2015 /req/multi-lingual/package]")
							globalErrorCounter = globalErrorCounter + 1 
						end if 
					
						'Check if the value contains  illegal quotation marks, gives an Warning-message  
						dim startContent, endContent, designationContent
	
						startContent = InStr( currentExistingTaggedValue1.Value, """" ) 			
						endContent = len(currentExistingTaggedValue1.Value)- InStr( StrReverse(currentExistingTaggedValue1.Value), """" ) -1
						if endContent<0 then endContent=0
						designationContent = Mid(currentExistingTaggedValue1.Value,startContent+1,endContent)				

						if InStr(designationContent, """") then
							if globalLogLevelIsWarning then
								Session.Output("Warning: Package [«" &theElement.Stereotype& "» " &theElement.Name&"] tag [" &taggedValueName& "] has a value ["&currentExistingTaggedValue1.Value&"] that contains illegal use of quotation marks.")
								globalWarningCounter = globalWarningCounter + 1 
							end if	
						end if
					else
						Session.Output("Error: Package [«" &theElement.Stereotype& "» " &theElement.Name& "] tag [" &taggedValueName& "] has no value [ISO19109:2015 /req/multi-lingual/package]") 
						globalErrorCounter = globalErrorCounter + 1
					end if
				end if 						
			next

		end if 
	end if
end sub 
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Script Name: structurOfTVforElement
' Original author (SOSI version): Sara Henriksen
' Adaption to ISO19109:2015 version:  Åsmund Tjora
' Date: 18.05.17	
' Purpose: Check that the value of a designation/description/definition tag got the structure “{value}”@{langcode}. 
' Implemented for objecttypes, attributes, roles and operations.
' Two subs, where structurOfTVforElement calls structureOfTVConnectorEnd if the parameter is a connector
' req/multi-lingual/feature
' sub procedure to find the provided tags for a connector, and if they exist, check the structure of the value.   
' @param[in]: theConnectorEnd (EA.Connector), taggedValueName (string) theConnectorEnd is potencially having tags: description, designation, definition, 
' with a value with wrong structure. 
sub structureOfTVConnectorEnd(theConnectorEnd,  taggedValueName)

	if not theConnectorEnd is nothing and Len(taggedValueName) > 0 then
	
		'check if the element has a tagged value with the provided name
		dim currentExistingTaggedValue as EA.RoleTag 
		dim taggedValuesCounter

		for taggedValuesCounter = 0 to theConnectorEnd.TaggedValues.Count - 1
			set currentExistingTaggedValue = theConnectorEnd.TaggedValues.GetAt(taggedValuesCounter)

			'if the tagged values exist, check the structure of the value 
			if currentExistingTaggedValue.Tag = taggedValueName then
				'check if the structure of the tag is: "{value}"@{languagecode}
				if not (InStr(currentExistingTaggedValue.Value,"""@")>=2 and InStr(currentExistingTaggedValue.Value,"""") =1 ) then
					Session.Output("Error: Role [" &theConnectorEnd.Role& "] tag [" &currentExistingTaggedValue.Tag& "] has a value [" &currentExistingTaggedValue.Value& "] with wrong structure. Expected structure: ""{Name}""@{language}. [ISO19109:2015 /req/multi-lingual/feature]")
					globalErrorCounter = globalErrorCounter + 1 
				end if 
			end if 
		next
	end if 
end sub 
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'sub procedure to find the provided tags and if they exist, check the structure of the value.   
'@param[in]: theElement (EA.ObjectType), taggedValueName (string) The object to check against req/multi-lingual/feature,  
'supposed to be one of the following types: EA.Element, EA.Attribute, EA.Method, EA.Connector 
sub structurOfTVforElement (theElement, taggedValueName)

	if not theElement is nothing and Len(taggedValueName) > 0 and not theElement.ObjectType = otConnectorEnd   then

		'check if the element has a tagged value with the provided name
		dim currentExistingTaggedValue AS EA.TaggedValue 
		dim taggedValuesCounter

		for taggedValuesCounter = 0 to theElement.TaggedValues.Count - 1
			set currentExistingTaggedValue = theElement.TaggedValues.GetAt(taggedValuesCounter)

			if currentExistingTaggedValue.Name = taggedValueName then
				'check the structure of the tag: "{value}"@{languagecode}
				if not (InStr(currentExistingTaggedValue.Value,"""@")>=2 and InStr(currentExistingTaggedValue.Value,"""") =1 ) then
					Dim currentElement as EA.Element
					Dim currentAttribute as EA.Attribute
					Dim currentOperation as EA.Method
					
					Select Case theElement.ObjectType 
						'case element
						Case otElement 
							set currentElement = theElement 
						
							Session.Output("Error: Class [«"&theElement.Stereotype&"» " &theElement.Name& "] tag [" &currentExistingTaggedValue.Name& "] has a value [" &currentExistingTaggedValue.Value& "] with wrong structure. Expected structure: ""{Name}""@{language}. [ISO19109:2015 /req/multi-lingual/feature]")
							globalErrorCounter = globalErrorCounter + 1 
						
						'case attribute
						Case otAttribute
							set currentAttribute = theElement
						
							'get the element (class, enumeration, data Type) the attribute belongs to
							dim parentElementOfAttribute as EA.Element
							set parentElementOfAttribute = Repository.GetElementByID(currentAttribute.ParentID)
						
							Session.Output("Error: Class [«"& parentElementOfAttribute.Stereotype &"» "& parentElementOfAttribute.Name &" attribute [" &theElement.Name& "] tag [" &currentExistingTaggedValue.Name& "] has a value [" &currentExistingTaggedValue.Value& "] with wrong structure. Expected structure: ""{Name}""@{language}. [ISO19109:2015 /req/multi-lingual/feature]")
							globalErrorCounter = globalErrorCounter + 1 
						
						'case operation
						Case otMethod
							set currentOperation = theElement
							
							'get the element (class, enumeration, data Type) the operation belongs to
							dim parentElementOfOperation as EA.Element
							set parentElementOfOperation = Repository.GetElementByID(currentOperation.ParentID)
						
							Session.Output("Error: Class [«"& parentElementOfOperation.Stereotype &"» "& parentElementOfOperation.Name &" operation [" &theElement.Name& "] tag [" &currentExistingTaggedValue.Name& "] has a value: " &currentExistingTaggedValue.Value& " with wrong structure. Expected structure: ""{Name}""@{language}. [ISO19109:2015 /req/multi-lingual/feature]")
							globalErrorCounter = globalErrorCounter + 1 

					end select 	
				end if 
			end if 
		next
	'if the element is a connector then call another sub routine 
	elseif theElement.ObjectType = otConnectorEnd then
		Call structureOfTVConnectorEnd(theElement, taggedValueName)
	end if 
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Script Name: checkValueOfTVVersion
' Author: Sara Henriksen
' Date: 25.07.16 
' Purpose: To check if the value of the version-tag (tagged values) for an ApplicationSchema-package is empty or not. 
' 19109:2015 /req/uml/packaging
' sub procedure to check if the tagged value with the provided name exist in the ApplicationSchema, and if the value is emty it returns an Error-message. 
' @param[in]: theElement (Element Class) and TaggedValueName (String) 
sub checkValueOfTVVersion(theElement, taggedValueName)

	if UCase(theElement.stereotype) = UCase("applicationSchema") then

		if not theElement is nothing and Len(taggedValueName) > 0 then

			'check if the element has a tagged value with the provided name
			dim taggedValueVersionMissing
			taggedValueVersionMissing = true
			dim currentExistingTaggedValue AS EA.TaggedValue 
			dim taggedValuesCounter
			for taggedValuesCounter = 0 to theElement.TaggedValues.Count - 1
				set currentExistingTaggedValue = theElement.TaggedValues.GetAt(taggedValuesCounter)
			
				'check if the taggedvalue exists, and if so, checks if the value is empty or not. An empty value will give an error-message. 
				if currentExistingTaggedValue.Name = taggedValueName then
					'remove spaces before and after a string, if the value only contains blanks  the value is empty
					currentExistingTaggedValue.Value = Trim(currentExistingTaggedValue.Value)
					if len (currentExistingTaggedValue.Value) = 0 then 
						Session.Output("Error: Package [«"&theElement.Stereotype&"» " &theElement.Name&"] has an empty version-tag. [ISO19109:2015 /req/uml/packaging]")
						globalErrorCounter = globalErrorCounter + 1 
						taggedValueVersionMissing = false 
					else
						taggedValueVersionMissing = false 
						'Session.Output("[" &theElement.Name& "] has version tag:  " &currentExistingTaggedValue.Value)
					end if 
				end if
			next
			'if tagged value version lacks for the package, return an error 
			if taggedValueVersionMissing then
				Session.Output ("Error: Package [«"&theElement.Stereotype&"» " &theElement.Name&"] lacks a [version] tag. [ISO19109:2015 /req/uml/packaging]")
				globalErrorCounter = globalErrorCounter + 1 
			end if
		end if 
	end if
end sub 
'-------------------------------------------------------------END-------------------------------------------------------------------------------------------- 
 

'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Script Name: checkConstraint
' Author: Sara Henriksen
' Date: 26.08.16
' Purpose: to check if a constraint lacks name or definition. 
' [ISO19109:2015 /req/uml/constraint] & [ISO19109:2015 /req/uml/documentation]
' sub procedure to check the current element/attribute/connector/package for constraints without name or definition
' not sure if it is possible in EA that constraints without names can exist, checking it anyways
' @param[in]: currentConstraint (EA.Constraint) theElement (EA.ObjectType) The object to check against [ISO19109:2015 /req/uml/constraint],  
' supposed to be one of the following types: EA.Element, EA.Attribute, EA.Connector, EA.package

sub checkConstraint(currentConstraint, theElement)
	
	dim currentConnector as EA.Connector
	dim currentElement as EA.Element
	dim currentAttribute as EA.Attribute
	dim currentPackage as EA.Package
	
	Select Case theElement.ObjectType

		'if the object is an element
		Case otElement 
		set currentElement = theElement 
		
		'if the current constraint lacks definition, then return an error
		if currentConstraint.Notes= "" then 
			Session.Output("Error: Class [«"&theElement.Stereotype&"» "&theElement.Name&"] \ constraint [" &currentConstraint.Name&"] lacks definition. [ISO19109:2015 /req/uml/constraint] & [ISO19109:2015 /req/uml/documentation]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
		
		'if the current constraint lacks a name, then return an error 
		if currentConstraint.Name = "" then
			Session.Output("Error: Class [«" &theElement.Stereotype& "» "&currentElement.Name& "] has a constraint without a name. [ISO19109:2015 /req/uml/constraint]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
		
		'if the object is an attribute 
		Case otAttribute
		set currentAttribute = theElement 
		
		'if the current constraint lacks definition, then return an error
		dim parentElementID
		parentElementID = currentAttribute.ParentID
		dim parentElementOfAttribute AS EA.Element
		set parentElementOfAttribute = Repository.GetElementByID(parentElementID)
		if currentConstraint.Notes= "" then 
			Session.Output("Error: Class ["&parentElementOfAttribute.Name&"] \ attribute ["&theElement.Name&"] \ constraint [" &currentConstraint.Name&"] lacks definition. [ISO19109:2015 /req/uml/constraint] & [ISO19109:2015 /req/uml/documentation]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
		
		'if the current constraint lacks a name, then return an error 	
		if currentConstraint.Name = "" then
			Session.Output("Error: Attribute ["&theElement.Name& "] has a constraint without a name. [ISO19109:2015 /req/uml/constraint]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
		
		Case otPackage
		set currentPackage = theElement
		
		'if the current constraint lacks definition, then return an error message
		if currentConstraint.Notes= "" then 
			Session.Output("Error: Package [«"&theElement.Element.Stereotype&"» "&theElement.Name&"] \ constraint [" &currentConstraint.Name&"] lacks definition. [ISO19109:2015 /req/uml/constraint] & [ISO19109:2015 /req/uml/documentation]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
		
		'if the current constraint lacks a name, then return an error meessage		
		if currentConstraint.Name = "" then
			Session.Output("Error: Package [«" &theElement.Element.Stereotype&"» " &currentElement.Name& "] has a constraint without a name. [ISO19109:2015 /req/uml/constraint]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
			
		Case otConnector
		set currentConnector = theElement
		
		'if the current constraint lacks definition, then return an error message
		if currentConstraint.Notes= "" then 
		
			dim sourceElementID
			sourceElementID = currentConnector.ClientID
			dim sourceElementOfConnector AS EA.Element
			set sourceElementOfConnector = Repository.GetElementByID(sourceElementID)
			
			dim targetElementID
			targetElementID = currentConnector.SupplierID
			dim targetElementOfConnector AS EA.Element
			set targetElementOfConnector = Repository.GetElementByID(targetElementID)
		
			Session.Output("Error: Constraint [" &currentConstraint.Name&"] owned by connector [ "&theElement.Name&"] between class ["&sourceElementOfConnector.Name&"] and class ["&targetElementOfConnector.Name&"] lacks definition. [ISO19109:2015 /req/uml/constraint] & [ISO19109:2015 /req/uml/documentation]")
			globalErrorCounter = globalErrorCounter + 1 
		end if 
		
		'if the current constraint lacks a name, then return an error message		
		if currentConstraint.Name = "" then
			Session.Output("Error: Connector [" &theElement.Name& "] has a constraint without a name. [ISO19109:2015 /req/uml/constraint]")
			globalErrorCounter = globalErrorCounter + 1 
		
		end if
	end select
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------
 
 
'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Script Name: checkNumericinitialValues
' Author: Sara Henriksen
' Date: 27.07.16
' Purpose: checks every initial values in  codeLists and enumerations for a package. Returns a warning for each attribute with intitial value that is numeric 
' [ISO19103:2015 Recommendation 1] 
'sub procedure to check if the initial values of the attributes in a CodeList/enumeration are numeric or not. 
'@param[in]: theElement (EA.element) The element containing  attributes with potentially numeric inital values 
sub checkNumericinitialValues(theElement)

	dim attr as EA.Attribute
	dim numberOfNumericDefault

	'navigate through all attributes in the codeLists/enumeration 
	for each attr in theElement.Attributes 
		'check if the initial values are numeric 
		if IsNumeric(attr.Default)   then
			if globalLogLevelIsWarning then	
				Session.Output("Warning: Class [«"&theElement.Stereotype&"» "&theElement.Name&"] \ attribute [" &attr.Name& "] has numeric initial value [" &attr.Default& "] that is probably meaningless. [ISO19103:2015 Recommendation 1]")		
				globalWarningCounter = globalWarningCounter + 1 
			end if
		end if 
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
'sub procedure to check if the provided tag exist (codeList), and if so, check  if the value is empty or not
'@param[in]: theElement (Element Class) and TaggedValueName (String)

sub CheckCodelistTV (theElement,  taggedValueNAME)

	'iterate tagged Values 
	dim currentExistingTaggedValue AS EA.TaggedValue 
	dim taggedValueCodeListMissing
	taggedValueCodeListMissing = true
	dim taggedValuesCounter
	
	for taggedValuesCounter = 0 to theElement.TaggedValues.Count - 1
		set currentExistingTaggedValue = theElement.TaggedValues.GetAt(taggedValuesCounter)
		'check if the tagged value exists
		if UCase(currentExistingTaggedValue.Name) = UCase(taggedValueName) then
						
			'if the codeList-value is empty, return an error 
			if currentExistingTaggedValue.Value = "" then 
				if globalLogLevelIsWarning then
					Session.Output("Warning: Class [«"&theElement.Stereotype&"» "&theElement.Name& "] \ tag ["& taggedValueName &"] lacks value. [ISO19103:2015 Recommendation 4]")
					globalWarningCounter = globalWarningCounter + 1 
				end if
			end if 
		end if 
	next
	
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


' -----------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: requirement6
' Author: Kent Jonsrud
' Date: 2016-08-04
' Purpose: 
    'test if element name is legal NCName
    'some characters to avoid are: blank, komma, !, "", #, $, %, &, ', (, ), *, +, /, :, ;, <, =, >, ?, @, [, \, ], ^, `, {, |, }, ~
	'characters below 32 or names starting with a number are also illegal

sub requirement6(theElement)
	
	
	dim attr as EA.Attribute
	
	dim numberInList
	numberInList = 0
	
	'navigate through all attributes in the codeLists/enumeration 
	for each attr in theElement.Attributes
		'count number of attributes in one list
		numberInList = numberInList + 1 
		'check if the name is NCName
		if NOT IsNCName(attr.Name) then
			'count number of numeric initial values for one list
			globalErrorCounter = globalErrorCounter +  1
			Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has illegal code name ["&attr.Name&"].  [ISO19103:2015 requirement6]")
		
		end if 
		
	next
			
end sub

Function hasNoWhiteSpace(inputString)
	dim i
	dim retVal
	retVal=true
	for i=1 to len(inputString)
		if mid(inputString,i,1)=" " then retVal=false
	next
	hasNoWhiteSpace=retVal
end function



Function IsNCName(streng)
    Dim txt, res, tegn, i, u
    u = true
	txt = ""
	For i = 1 To Len(streng)
        tegn = Mid(streng,i,1)
	    if tegn = " " or tegn = "," or tegn = """" or tegn = "#" or tegn = "$" or tegn = "%" or tegn = "&" or tegn = "(" or tegn = ")" or tegn = "*" Then
		    u=false
		end if 
	
		if tegn = "+" or tegn = "/" or tegn = ":" or tegn = ";" or tegn = "<" or tegn = ">" or tegn = "?" or tegn = "@" or tegn = "[" or tegn = "\" Then
		    u=false
		end if 
		If tegn = "]" or tegn = "^" or tegn = "`" or tegn = "{" or tegn = "|" or tegn = "}" or tegn = "~" or tegn = "'" or tegn = "´" or tegn = "¨" Then
		    u=false
		end if 
		if tegn <  " " then
		    u=false
		end if
	next
	tegn = Mid(streng,1,1)
	if tegn = "1" or tegn = "2" or tegn = "3" or tegn = "4" or tegn = "5" or tegn = "6" or tegn = "7" or tegn = "8" or tegn = "9" or tegn = "0" or tegn = "-" or tegn = "." Then
		u=false
	end if 
	IsNCName = u
End Function
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: requirement7CodeDefinition
' Author: Kent Jonsrud
' Date: 2016-08-05
' Purpose: 
 	' test if element has definition
	'19103:2015 requirement 7

sub requirement7CodeDefinition(theElement)
	
	dim attr as EA.Attribute
	
	'navigate through all attributes in the codeLists/enumeration 
	for each attr in theElement.Attributes
		if attr.Notes = "" then
			Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] is missing definition for code ["&attr.Name&"]. [ISO19103:2015 requirement 7]")
			globalErrorCounter = globalErrorCounter + 1
		end if 
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name:	requirement14
' Author: 	Tore Johnsen
' Date: 	2016-08-22
' Purpose: 	Checks that there is no inheritance between classes with unequal stereotypes.
'		   	ISO19103:2015 Requirement14
' @param[in]: currentElement

sub requirement14(currentElement)

	dim connectors as EA.Collection
	set connectors = currentElement.Connectors
	dim connectorsCounter
	
	for connectorsCounter = 0 to connectors.Count - 1
		dim currentConnector as EA.Connector
		set currentConnector = connectors.GetAt( connectorsCounter )
		dim targetElementID
		targetElementID = currentConnector.SupplierID
		dim elementOnOppositeSide as EA.Element
					
		if currentConnector.Type = "Generalization" then
			set elementOnOppositeSide = Repository.GetElementByID(targetElementID)
			
			if globalLogLevelIsWarning then
				if UCase(elementOnOppositeSide.Stereotype) <> UCase(currentElement.Stereotype) then
					session.output("Warning: Class [«"&elementOnOppositeSide.Stereotype&"» "&elementOnOppositeSide.Name&"] has a stereotype that is not the same as the stereotype of [«"&currentElement.Stereotype&"» "&currentElement.Name&"]. Check if they are at the same abstraction level. [ISO19103:2015 Requirement 14]")
					globalWarningCounter = globalWarningCounter + 1
				end if
			end if
		end if
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: reqGeneralFeature
' Author: 	Tore Johnsen
' Date: 	2017-02-22
' Purpose: 	Checks that no classes with stereotype «FeatureType» inherits from a class named GM_Object or TM_Object.
'			ISO19109:2015 req/general/feature
' @param[in]: currentElement, startClass

sub reqGeneralFeature(currentElement, startClass)
	
	dim superClass as EA.Element
	dim connector as EA.Connector

	for each connector in currentElement.Connectors
		if connector.Type = "Generalization" then
			if UCASE(currentElement.Stereotype) = "FEATURETYPE" then
				if currentElement.ElementID = connector.ClientID then
					set superClass = Repository.GetElementByID(connector.SupplierID)

					if UCASE(superClass.Name) = "GM_OBJECT" or UCASE(superClass.Name) = "TM_OBJECT" and UCASE(currentElement.Stereotype) = "FEATURETYPE" and UCASE(superClass.Stereotype) = "FEATURETYPE" then
					session.output("Error: Class [" & startClass.Name & "] inherits from class [" & superclass.name & "] [ISO19109:2015 /req/general/feature]")
					globalErrorCounter = globalErrorCounter + 1
					else call reqGeneralFeature(superClass, startClass)
					end if
				end if
			end if
		end if
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


' -----------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: checkKnownStereotypes
' Author: Kent Jonsrud
' Date: 2016-08-05
' Purpose: 
    '[ISO19103 Requirement 15] - warning if not a standardised stereotype
	'this is not implemented as an error since there can be reasons for new stereotypes with different meaning than the standardised stereotypes

sub checkKnownStereotypes(theElement)
	dim goodNames, badName, badStereotype, roleName
	goodNames = true
	dim attr as EA.Attribute
	dim conn as EA.Collection
	dim numberOfFaults
	numberOfFaults = 0
	dim numberInList
	numberInList = 0
	
	'navigate through all attributes  
	for each attr in theElement.Attributes
		numberInList = numberInList + 1 
		if attr.Stereotype <> "" then
			numberOfFaults = numberOfFaults + 1
			if globalLogLevelIsWarning then
				Session.Output("Warning: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has unknown stereotype. «" & attr.Stereotype & "» on attribute ["&attr.Name&"]. [ISO19103 Requirement 15]")
				globalWarningCounter = globalWarningCounter + 1
			end if	
			if goodNames then
				badName = attr.Name
				badStereotype = attr.Stereotype
			end if
			goodNames = false 
		end if 
	next
	
	'if one or more codes lack definition, warning.
	if goodNames = false then 
		if globalLogLevelIsWarning then
			globalWarningCounter = globalWarningCounter + 1
		end if	
	end if

	'operations?
	
	'Association roles with stereotypes other than «estimated»
	for each conn in theElement.Connectors
		roleName = ""
		badStereotype = ""
		if theElement.ElementID = conn.ClientID then
			roleName = conn.SupplierEnd.Role
			badStereotype = conn.SupplierEnd.Stereotype
		end if
		if theElement.ElementID = conn.SupplierID then
			roleName = conn.ClientEnd.Role
			badStereotype = conn.ClientEnd.Stereotype
		end if
		'(ignoring all association roles without name!)
		if roleName <> "" then
			if badStereotype <> "" and LCase(badStereotype) <> "estimated" then
				if globalLogLevelIsWarning then
					Session.Output("Warning: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] as unknown stereotype «"&badStereotype&"» on role name ["&roleName&"]. [ISO19103 Requirement 15]")				
					globalWarningCounter = globalWarningCounter + 1 
				end if	
			end if
		end if
	next
	
	'Associations with stereotype, especially «topo»
	for each conn in theElement.Connectors
		if conn.Stereotype <> "" then
			
				if globalLogLevelIsWarning then
					Session.Output("Warning: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has unknown stereotype «"&conn.Stereotype&"» on association named ["&conn.Name&"]. [ISO19103 Requirement 15]")				
					globalWarningCounter = globalWarningCounter + 1 
				end if	
		end if
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


' -----------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: requirement16UniqueNCname
' Author: Kent Jonsrud
' Date: 2016-08-09
' Purpose: 
    'ISO19103:2015 requirement 16
 
sub requirement16UniqueNCname(theElement)
	
	dim goodNames, lowerCameCase, badName, roleName
	goodNames = true
	lowerCameCase = true
	dim super as EA.Element
	dim attr as EA.Attribute
	dim oper as EA.Collection
	dim conn as EA.Collection
	dim numberOfFaults
	numberOfFaults = 0
	dim numberInList
	numberInList = 0

	dim PropertyNames
	Set PropertyNames = CreateObject("System.Collections.ArrayList")

	'List of element IDs to check for endless recursion (Åsmund)
	dim inheritanceElementList
	set inheritanceElementList = CreateObject("System.Collections.ArrayList")

	'Association role names
	for each conn in theElement.Connectors
		roleName = ""
		if theElement.ElementID = conn.ClientID then
			roleName = conn.SupplierEnd.Role
		end if
		if theElement.ElementID = conn.SupplierID then
			roleName = conn.ClientEnd.Role
		end if
		'(ignoring all association roles without name!)
		if roleName <> "" then
			if PropertyNames.IndexOf(UCase(roleName),0) <> -1 then
				Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has non-unique role name ["&roleName&"]. [ISO19103:2015 Requirement 16]")				
 				globalErrorCounter = globalErrorCounter + 1 
			else
				PropertyNames.Add UCase(roleName)
			end if
			if NOT hasNoWhiteSpace(roleName) then
				Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has illegal role name, ["&roleName&"] contains whitespace. [ISO19103:2015 Requirement 16]")				
 				globalErrorCounter = globalErrorCounter + 1 
			end if
		end if
	next
	
	'Operation names
	for each oper in theElement.Methods
		if PropertyNames.IndexOf(UCase(oper.Name),0) <> -1 then
			Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has non-unique operation property name ["& oper.Name &"]. [ISO19103:2015 Requirement 16]")				
			globalErrorCounter = globalErrorCounter + 1 
		else
			PropertyNames.Add UCase(oper.Name)
		end if
		'check if the name is NCName
		if NOT hasNoWhiteSpace(oper.Name) then
				Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has illegal operation name, ["& oper.Name &"] contains whitespace. [ISO19103:2015 Requirement 16]")				
 				globalErrorCounter = globalErrorCounter + 1 
		end if 
	next
	
	'Constraint names TODO
	
	'navigate through all attributes 
	for each attr in theElement.Attributes
		'count number of attributes in one list
		numberInList = numberInList + 1 
		if PropertyNames.IndexOf(UCase(attr.Name),0) <> -1 then
			Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has non-unique attribute property name ["&attr.Name&"]. [ISO19103:2015 Requirement 16]")				
			globalErrorCounter = globalErrorCounter + 1 
		else
			PropertyNames.Add UCase(attr.Name)
		end if

		'check if the name is NCName (exception for code names - they have a separate test.)
		if NOT ((theElement.Type = "Class") and (UCase(theElement.Stereotype) = "CODELIST"  Or UCase(theElement.Stereotype) = "ENUMERATION")) then
			if NOT hasNoWhiteSpace(attr.Name) then
				'count number of numeric initial values for one list
				Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has illegal attribute name, ["&attr.Name&"] contains whitespace. [ISO19103:2015 Requirement 16]")				
 				globalErrorCounter = globalErrorCounter + 1 
			end if
		end if 
	next

	'Other attributes and roles inherited from outside package
	'Traverse and test against inherited names but do not add the inherited names to the list(!)
	for each conn in theElement.Connectors

		if conn.Type = "Generalization" then
			if theElement.ElementID = conn.ClientID then
				set super = Repository.GetElementByID(conn.SupplierID)
				
				'Check agains endless recursion (Åsmund)
				dim hopOutOfEndlessRecursion
				dim inheritanceElementID
				hopOutOfEndlessRecursion = 0
				inheritanceElementList.Add(theElement.ElementID)
				for each inheritanceElementID in inheritanceElementList
					if inheritanceElementID = super.ElementID then 
						hopOutOfEndlessRecursion = 1
						Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] is a generalization of itself.")
						globalErrorCounter = globalErrorCounter + 1
					end if
				next
				if hopOutOfEndlessRecursion=0 then call requirement16uniqueNCnameInherited(super, PropertyNames, inheritanceElementList)
			end if
		end if
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


' -----------------------------------------------------------START-------------------------------------------------------------------------------------------
sub requirement16uniqueNCnameInherited(theElement, PropertyNames, inheritanceElementList)
	dim goodNames, lowerCameCase, badName, roleName
	goodNames = true
	lowerCameCase = true
	dim super as EA.Element
	dim attr as EA.Attribute
	dim oper as EA.Collection
	dim conn as EA.Collection
 	dim numberOfFaults
	numberOfFaults = 0
	dim numberInList
	numberInList = 0

	'Association role names
	for each conn in theElement.Connectors

		roleName = ""
		if theElement.ElementID = conn.ClientID then
			roleName = conn.SupplierEnd.Role
		end if
		if theElement.ElementID = conn.SupplierID then
			roleName = conn.ClientEnd.Role
		end if
		'(ignoring all association roles without name!)
		if roleName <> "" then
			if PropertyNames.IndexOf(UCase(roleName),0) <> -1 then
				if globalLogLevelIsWarning then
					Session.Output("Warning: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] in package: ["&Repository.GetPackageByID(theElement.PackageID).Name&"] has non-unique inherited role property name ["&roleName&"] implicitly redefined from. [ISO19103:2015 Requirement 16]")				
					globalWarningCounter = globalWarningCounter + 1
				end if	
			end if
		end if
	next
	
	'Operation names
	for each oper in theElement.Methods
		if PropertyNames.IndexOf(UCase(oper.Name),0) <> -1 then
			if globalLogLevelIsWarning then
				Session.Output("Warning: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] in package: ["&Repository.GetPackageByID(theElement.PackageID).Name&"] has inherited and implicitly redefined non-unique operation property name ["& oper.Name&"]. [ISO19103:2015 Requirement 16]")				
				globalWarningCounter = globalWarningCounter + 1
			end if	
		end if
	next
	
	'Constraint names TODO
	
	'navigate through all attributes 
	for each attr in theElement.Attributes
		'count number of attributes in one list
		numberInList = numberInList + 1 
		if PropertyNames.IndexOf(UCase(attr.Name),0) <> -1 then
			if globalLogLevelIsWarning then
				Session.Output("Warning: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] in package: ["&Repository.GetPackageByID(theElement.PackageID).Name&"] has non-unique inherited and implicitly redefined attribute property name["&attr.Name&"]. [ISO19103:2015 Requirement 16]")				
				globalWarningCounter = globalWarningCounter + 1
			end if	
		end if
	next

	'Other attributes and roles inherited from outside package
	'Traverse and test against inherited names but do not add the inherited names to the list
	for each conn in theElement.Connectors
		if conn.Type = "Generalization" then
			if theElement.ElementID = conn.ClientID then
				set super = Repository.GetElementByID(conn.SupplierID)
				'Check agains endless recursion (Åsmund)
				dim hopOutOfEndlessRecursion
				dim inheritanceElementID
				hopOutOfEndlessRecursion = 0
				inheritanceElementList.Add(theElement.ElementID)
				for each inheritanceElementID in inheritanceElementList
					if inheritanceElementID = super.ElementID then 
						hopOutOfEndlessRecursion = 1
						Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] is a generalization of itself.")
						globalErrorCounter = globalErrorCounter + 1
					end if
				next
				if hopOutOfEndlessRecursion=0 then call requirement16uniqueNCnameInherited(super, PropertyNames, inheritanceElementList)
			end if
		end if
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


' -----------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: reqUmlProfile
' Author: Kent Jonsrud 2017-05-18
' Date: 2016-08-08, 2017-05-13
' Purpose: 
    'iso19109:2015 /req/uml/profile , includes iso109103:2015 requirement 25 and requirement 22.


sub reqUmlProfile(theElement)
	
	dim attr as EA.Attribute
	'navigate through all attributes 
	for each attr in theElement.Attributes
		if attr.ClassifierID = 0 then
			'Attribute not connected to a datatype class, check if the attribute has a iso TC 211 well known type
			if ProfileTypes.IndexOf(attr.Type,0) = -1 then	
				if ExtensionTypes.IndexOf(attr.Type,0) = -1 then	
					if CoreTypes.IndexOf(attr.Type,0) = -1 then	
						Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has unknown type for attribute ["&attr.Name&" : "&attr.Type&"]. [ISO19109:2015 /req/uml/profile & ISO19103:2015 Requirement 25 & ISO19103:2015 Requirement 22]")
						globalErrorCounter = globalErrorCounter + 1 
					end if
				end if
			end if
		end if 
	next

end sub

sub requirement25(theElement)
	
	dim attr as EA.Attribute
	'navigate through all attributes 
	for each attr in theElement.Attributes
		if attr.ClassifierID = 0 then
			'Attribute not connected to a datatype class, check if the attribute has a iso 19103 type
				
				if ExtensionTypes.IndexOf(attr.Type,0) = -1 then	
					if CoreTypes.IndexOf(attr.Type,0) = -1 then	
						Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has unknown type for attribute ["&attr.Name&" : "&attr.Type&"]. [ISO19103:2015 Requirement 25 & ISO19103:2015 Requirement 22]")
						globalErrorCounter = globalErrorCounter + 1 
					end if
				end if
			
		end if 
	next

end sub

sub requirement22(theElement)
	
	dim attr as EA.Attribute
	'navigate through all attributes 
	for each attr in theElement.Attributes
		if attr.ClassifierID = 0 then
			'Attribute not connected to a datatype class, check if the attribute has a iso 19103 type
			
					if CoreTypes.IndexOf(attr.Type,0) = -1 then	
						Session.Output("Error: Class [«" &theElement.Stereotype& "» " &theElement.Name& "] has unknown type for attribute ["&attr.Name&" : "&attr.Type&"]. [ISO19103:2015 Requirement 22]")
						globalErrorCounter = globalErrorCounter + 1 
					end if
				
		end if 
	next

end sub

sub reqUmlProfileLoad()
	
	'iso 19103:2015 Core types
	CoreTypes.Add "Date"
	CoreTypes.Add "Time"
	CoreTypes.Add "DateTime"
	CoreTypes.Add "CharacterString"
	CoreTypes.Add "Number"
	CoreTypes.Add "Decimal"
	CoreTypes.Add "Integer"
	CoreTypes.Add "Real"
	CoreTypes.Add "Boolean"
	CoreTypes.Add "Vector"

	CoreTypes.Add "Bit"
	CoreTypes.Add "Digit"
	CoreTypes.Add "Sign"

	CoreTypes.Add "NameSpace"
	CoreTypes.Add "GenericName"
	CoreTypes.Add "LocalName"
	CoreTypes.Add "ScopedName"
	CoreTypes.Add "TypeName"
	CoreTypes.Add "MemberName"

	CoreTypes.Add "Any"

	CoreTypes.Add "Record"
	CoreTypes.Add "RecordType"
	CoreTypes.Add "Field"
	CoreTypes.Add "FieldType"
	
	'iso 19103:2015 Annex-C types
	ExtensionTypes.Add "LanguageString"
	
	ExtensionTypes.Add "Anchor"
	ExtensionTypes.Add "FileName"
	ExtensionTypes.Add "MediaType"
	ExtensionTypes.Add "URI"
	
	ExtensionTypes.Add "UnitOfMeasure"
	ExtensionTypes.Add "UomArea"
	ExtensionTypes.Add "UomLenght"
	ExtensionTypes.Add "UomAngle"
	ExtensionTypes.Add "UomAcceleration"
	ExtensionTypes.Add "UomAngularAcceleration"
	ExtensionTypes.Add "UomAngularSpeed"
	ExtensionTypes.Add "UomSpeed"
	ExtensionTypes.Add "UomCurrency"
	ExtensionTypes.Add "UomVolume"
	ExtensionTypes.Add "UomTime"
	ExtensionTypes.Add "UomScale"
	ExtensionTypes.Add "UomWeight"
	ExtensionTypes.Add "UomVelocity"

	ExtensionTypes.Add "Measure"
	ExtensionTypes.Add "Length"
	ExtensionTypes.Add "Distance"
	ExtensionTypes.Add "Speed"
	ExtensionTypes.Add "Angle"
	ExtensionTypes.Add "Scale"
	ExtensionTypes.Add "TimeMeasure"
	ExtensionTypes.Add "Area"
	ExtensionTypes.Add "Volume"
	ExtensionTypes.Add "Currency"
	ExtensionTypes.Add "Weight"
	ExtensionTypes.Add "AngularSpeed"
	
	ExtensionTypes.Add "DirectedMeasure"
	ExtensionTypes.Add "Velocity"
	ExtensionTypes.Add "AngularVelocity"
	ExtensionTypes.Add "Acceleration"
	ExtensionTypes.Add "AngularAcceleration"
	
	'Table 26 + iso19109 7.5.2 valid spatial types from iso 19107:2003
	ProfileTypes.Add "DirectPosition"
	ProfileTypes.Add "GM_Object"
	ProfileTypes.Add "GM_Complex"
	ProfileTypes.Add "GM_Aggregate"
	ProfileTypes.Add "GM_Point"
	ProfileTypes.Add "GM_Curve"
	ProfileTypes.Add "GM_Surface"
	ProfileTypes.Add "GM_Solid"
	ProfileTypes.Add "GM_MultiPoint"
	ProfileTypes.Add "GM_MultiCurve"
	ProfileTypes.Add "GM_MultiSurface"
	ProfileTypes.Add "GM_MultiSolid"
	ProfileTypes.Add "GM_CompositePoint"
	ProfileTypes.Add "GM_CompositeCurve"
	ProfileTypes.Add "GM_CompositeSurface"
	ProfileTypes.Add "GM_CompositeSolid"
	ProfileTypes.Add "TP_Object"
	'ProfileTypes.Add "TP_Primitive"
	ProfileTypes.Add "TP_Complex"
	ProfileTypes.Add "TP_Node"
	ProfileTypes.Add "TP_Edge"
	ProfileTypes.Add "TP_Face"
	ProfileTypes.Add "TP_Solid"
	ProfileTypes.Add "TP_DirectedNode"
	ProfileTypes.Add "TP_DirectedEdge"
	ProfileTypes.Add "TP_DirectedFace"
	ProfileTypes.Add "TP_DirectedSolid"
	
	
	'Table 28 coverage types from iso 19123:2007
	ProfileTypes.Add "CV_Coverage"
	ProfileTypes.Add "CV_DiscreteCoverage"
	ProfileTypes.Add "CV_DiscretePointCoverage"
	ProfileTypes.Add "CV_DiscreteGridPointCoverage"
	ProfileTypes.Add "CV_DiscreteCurveCoverage"
	ProfileTypes.Add "CV_DiscreteSurfaceCoverage"
	ProfileTypes.Add "CV_DiscreteSolidCoverage"
	ProfileTypes.Add "CV_ContinousCoverage"
	ProfileTypes.Add "CV_ThiessenPolygonCoverage"
	ProfileTypes.Add "CV_ContinousQuadrilateralGridCoverage"
	ProfileTypes.Add "CV_HexagonalGridCoverage"
	ProfileTypes.Add "CV_TINCoverage"
	ProfileTypes.Add "CV_SegmentedCurveCoverage"

	'well known and often used temporal types from iso 19108:2006/2002?
	ProfileTypes.Add "TM_Instant"
	ProfileTypes.Add "TM_Period"
	ProfileTypes.Add "TM_Node"
	ProfileTypes.Add "TM_Edge"
	ProfileTypes.Add "TM_TopologicalComplex"
	
	'well known and often used observation related types from OM_Observation in iso 19156:2011
	ProfileTypes.Add "TM_Object"
	ProfileTypes.Add "NamedValue"
	
	'Table 22 well known and often used quality element types from iso 19157:2013
	ProfileTypes.Add "DQ_Element"
	ProfileTypes.Add "DQ_DataQuality"
	ProfileTypes.Add "DQ_AbsoluteExternalPositionalAccurracy"
	ProfileTypes.Add "DQ_RelativeInternalPositionalAccuracy"
	ProfileTypes.Add "DQ_GriddedDataPositionalAccuracy"
	ProfileTypes.Add "DQ_AccuracyOfATimeMeasurement"
	ProfileTypes.Add "DQ_TemporalConsistency"
	ProfileTypes.Add "DQ_TemporalValidity"
	ProfileTypes.Add "DQ_ThematicClassificationCorrectness"
	ProfileTypes.Add "DQ_NonQuantitativeAttributeCorrectness"
	ProfileTypes.Add "DQ_QuanatitativeAttributeAccuracy"

	ProfileTypes.Add "DQ_ConceptualConsistency"
	ProfileTypes.Add "DQ_DomainConsistency"
	ProfileTypes.Add "DQ_FormatConsistency"
	ProfileTypes.Add "DQ_TopologicalConsistency"
	ProfileTypes.Add "DQ_CompletenessCommission"
	ProfileTypes.Add "DQ_CompletenessOmission"
	ProfileTypes.Add "DQ_UsabilityElement"

	'referencing by geographical identifier types from iso 19112
	ProfileTypes.Add "LocationAttributeType"

	'well known and often used metadata element types from iso 19115-1:200x and iso 19139:2x00x
	
	'ProfileTypes.Add "CI_Citation"
	'ProfileTypes.Add "CI_Date"

end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: requirement18
' Author: Kent Jonsrud
' Date: 2016-08-09..30, 2016-09-05, 2017-01-17, 2017-05-13
' Purpose: test whether a class is showing all its content in at least one class diagram.

sub requirement18(theElement)

	dim diagram as EA.Diagram
	dim diagrams as EA.Collection
	dim diao as EA.DiagramObject
	dim conn as EA.Collection
	dim super as EA.Element
	dim base as EA.Collection
	dim child as EA.Collection
	dim embed as EA.Collection
	dim realiz as EA.Collection
	dim viserAlt
	viserAlt = false
	
	Dim i, shownTimes
	shownTimes=0
	For i = 0 To diaoList.Count - 1
		if theElement.ElementID = diaoList.GetByIndex(i) then
			set diagram = Repository.GetDiagramByID(diagList.GetByIndex(i))
			shownTimes = shownTimes + 1
			for each diao in diagram.DiagramObjects
				if diao.ElementID = theElement.ElementID then
					exit for
				end if
			next
			
			if theElement.Attributes.Count = 0 or InStr(1,diagram.ExtendedStyle,"HideAtts=1") = 0 then
				if theElement.Methods.Count = 0 or InStr(1,diagram.ExtendedStyle,"HideOps=1") = 0 then
					if InStr(1,diagram.ExtendedStyle,"HideEStereo=1") = 0 then
						if InStr(1,diagram.ExtendedStyle,"UseAlias=1") = 0 or theElement.Alias = "" then
							if (PropertiesShown(theElement, diagram, diao)) then
								viserAlt = true
							end if
						end if
					end if
				end if
			end if

		end if
	next
	
	if NOT viserAlt then
 		globalErrorCounter = globalErrorCounter + 1 
 		if shownTimes = 0 then
			Session.Output("Error: Class [«" &theElement.Stereotype& "» "&theElement.Name&"] is not shown in any diagram. [ISO19103:2015 requirement 18]")
		else
			Session.Output("Error: Class [«" &theElement.Stereotype& "» "&theElement.Name&"] is not shown fully in at least one diagram. [ISO19103:2015 requirement 18]")				
		end if
	end if
end sub



function PropertiesShown(theElement, diagram, diagramObject)

	dim conn as EA.Connector
	dim super as EA.Element
	dim diaos as EA.DiagramObject
	dim SuperpropertiesShown, InheritanceHandled, supername
	PropertiesShown = false
	SuperpropertiesShown = true
	InheritanceHandled = true
	supername = ""

	if InStr(1,diagram.ExtendedStyle,"HideAtts=1") = 0 and diagramObject.ShowPublicAttributes and InStr(1,diagramObject.Style,"AttCustom=1" ) = 0 or theElement.Attributes.Count = 0 then
		'Diagram Properties are set to show Attributes, or no Attributes in the class
		if InStr(1,diagram.ExtendedStyle,"HideOps=1") = 0 and diagramObject.ShowPublicOperations or InStr(1,diagramObject.Style,"OpCustom=0" ) <> 0 or theElement.Methods.Count = 0 then
			'Diagram Properties are set to show Operations, or no Operations in the class
			if InStr(1,diagram.ExtendedStyle,"ShowCons=0") = 0 or diagramObject.ShowConstraints or InStr(1,diagramObject.Style,"Constraint=1" ) <> 0 or theElement.Constraints.Count = 0 then
				'Diagram Properties are set to show Constraints, or no Constraints in the class
				' all attribute parts really shown? ...
				if InStr(1,diagram.StyleEX,"VisibleAttributeDetail=1" ) = 0 or theElement.Attributes.Count = 0 then
					'Feaure Visibility is set to show all Attributes
					if InStr(1,diagram.ExtendedStyle,"HideRel=0") = 1 or theElement.Connectors.Count = 0 then
						'Diagram Properties set up to show all Associations, or no Associations in the class				
						if AssociationsShown(theElement, diagram, diagramObject) then
							'All Associations shown ok
							'Must now recurce and check that all inherited elements are also shown in this diagram
							'Any Supertype exist?
								for each conn in theElement.Connectors
									if conn.Type = "Generalization" then
										if theElement.ElementID = conn.ClientID then 
											InheritanceHandled = false
											supername = Repository.GetElementByID(conn.SupplierID).Name
										end if
										for each diaos in diagram.DiagramObjects
											Set super = Repository.GetElementByID(diaos.ElementID)
											if super.ElementID <> theElement.ElementID and super.ElementID = conn.SupplierID then
												' Supertype found, recurce into it
												if (PropertiesShown(super, diagram, diaos) ) then
													'This Supertype is shown ok
												else
													SuperpropertiesShown = false
												end if
												InheritanceHandled = true
												'exit for? or is it posible to test multiple inheritance sicessfully?
											else
												' Class has subtype, it is not tested
											end if
										next
										if not InheritanceHandled then
											'Supertype may not be in this diagram at all
											SuperpropertiesShown = false
										end if
									else
									end if
								next
							'else
								'no supertypes
							'end if
							'are all inherited attributes shown in the class? and no inherited associations?
							if SuperpropertiesShown then PropertiesShown = true
						else
							'Session.Output("Info: Diagram ["&diagram.Name&"] not able to show all associations for class ["&theElement.Name&"]")				
						end if
					else
						'Session.Output("Info: Diagram ["&diagram.Name&"] Diagram Properties not set up to show any associations for class ["&theElement.Name&"]")				
					end if

					' All model elements are checked to be shown in the diagram.
					' But are there any other classes in the same diagram who are blocking full view of this element?
					'if ElementBlocked(theElement, diagram, dial) then
						'PropertiesShown = false
					'end if


					if PropertiesShown then
						'Session.Output("Info: Diagram ["&diagram.Name&"] OK, shows all attributes and operations in class ["&theElement.Name&"]")				
					end if
					
					' else
						'Session.Output("Info 5 Diagram ["&diagram.Name&"] Roles.....=0 and diagramObject.ShowConstraints=false or InStr(1,diagramObject.Style,'Constraint=1' ) <> 0 or theElement.Constraints.Count > 0.  ")
						'PropertiesShown = false
					' end if
				end if
			end if
		end if
	end if
end function


function AssociationsShown(theElement, diagram, diagramObject)
	dim i, roleEndElementID, roleEndElementShown, GeneralizationsFound
	dim dial as EA.DiagramLink
	dim connEl as EA.Connector
	dim conn as EA.Connector
	dim diaoRole as EA.DiagramObject
	AssociationsShown = false
	GeneralizationsFound = 0
	
	for each connEl in theElement.Connectors
		'test only for Association, Aggregation (+Composition) - leave out Generalization and Realisation and the rest
		if connEl.Type = "Generalization" or connEl.Type = "Realisation" then
			GeneralizationsFound = GeneralizationsFound + 1
		else
			for each dial in diagram.DiagramLinks
				Set conn = Repository.GetConnectorByID(dial.ConnectorID)
				if connEl.ConnectorID = conn.ConnectorID then
				'connector has diagramlink so it is shown in this diagram!
				
					'is the class at the other connector end actually shown in this diagram?
				'	roleEndElementShown = false
				'	if conn.ClientID = theElement.ElementID then
				'		roleEndElementID = conn.SupplierID
				'	else
				'		roleEndElementID = conn.ClientID
				'	end if
				'	for each diaoRole in diagram.DiagramObjects
				'		if diaoRole.ElementID = roleEndElementID then
				'				roleEndElementShown = true
				'			exit for
				'		end if
				'	next
				'		
						
						'this role property points to class at supplier end
				'		
				'		For i = 0 To diaoList.Count - 1
				'			if conn.SupplierID = diaoList.GetByIndex(i) then
				'				'shown at all?
				'				
				'				exit for
				'			end if
				'		next
	 
					AssociationsShown = true
				else
					'Session.Output("Debug: connector is not shown in this diagram ")
				end if

				'are the connector end elements (role name and multiplicity shown ok?
		'		if conn.ClientID = theElement.ElementID then
		'			if 
		'				AssociationsShown = true
		'				exit for
		'			end if
		'		end if
		'		if conn.SupplierID = theElement.ElementID then
		'			if 
		'				AssociationsShown = true
		'				exit for
		'			end if
		'		end if
		
			next
		end if
	next

	'are there any other connector end elements too close?

	if GeneralizationsFound > 0 and not AssociationsShown then
		if theElement.Connectors.Count = GeneralizationsFound then
			AssociationsShown = true
		end if
	else
		if theElement.Connectors.Count = 0 then
			AssociationsShown = true
		end if
	end if

end function


'Recursive loop through subpackages, creating a list of all model elements and their corresponding diagrams
sub recListDiagramObjects(p)
	
	dim d as EA.Diagram
	dim Dobj as EA.DiagramObject
	for each d In p.diagrams
		for each Dobj in d.DiagramObjects

				diaoList.Add Dobj.InstanceID, Dobj.ElementID
				diagList.Add Dobj.InstanceID, Dobj.DiagramID
   
		next	
	next
		
	dim subP as EA.Package
	for each subP in p.packages
	    recListDiagramObjects(subP)
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub name: checkDataTypeAssociation
' Author: Magnus Karge
' Date: 20170110 
' Purpose:  sub procedure to check if a given dataType element's (element with stereotype DataType or of type DataType) associations are 
'			compositions and the composition is on the correct end (datatypes must only be targets of compositions)
' 			Implementation of ISO19103:2015 Requirement 12
' 			
' @param[in]: 	theElement (EA.Element). The element to check. Can only be classifier of type data type or with stereotype dataType
'				theConnector (EA.Connector). The connector/association between theElement and theElementOnOppositeSide
'				theElementOnOppositeSide (EA.Element). The classifier on the other side of the connector/association
 
sub checkDataTypeAssociation(theElement, theConnector, theElementOnOppositeSide)
	dim currentElement AS EA.Element
	set currentElement = theElement
	dim elementOnOppositeSide AS EA.Element
	set elementOnOppositeSide = theElementOnOppositeSide
	dim currentConnector AS EA.Connector
	set currentConnector = theConnector
	
	dim dataTypeOnBothSides
	if (Ucase(currentElement.Stereotype) = Ucase("dataType") or currentElement.Type = "DataType") and (Ucase(elementOnOppositeSide.Stereotype) = Ucase("dataType") or elementOnOppositeSide.Type = "DataType") then
		dataTypeOnBothSides = true
	else	
		dataTypeOnBothSides = false
	end if
								
	'check if the elementOnOppositeSide has stereotype "dataType" and this side's end is no composition and not elements both sides of the association are datatypes
	if (Ucase(elementOnOppositeSide.Stereotype) = Ucase("dataType")) and not (currentConnector.ClientEnd.Aggregation = 2) and not dataTypeOnBothSides and currentConnector.Type <> "Dependency" then
		Session.Output( "Error: Class [«"&elementOnOppositeSide.Stereotype&"» "& elementOnOppositeSide.Name &"] has association to class [" & currentElement.Name & "] that is not a composition on "& currentElement.Name &"-side. [ISO19103:2015 Requirement 12]")									 
		globalErrorCounter = globalErrorCounter + 1 
	end if 

	'check if this side's element has stereotype "dataType" and the opposite side's end is no composition 
	if (Ucase(currentElement.Stereotype) = Ucase("dataType")) and not (currentConnector.SupplierEnd.Aggregation = 2) and not dataTypeOnBothSides and currentConnector.Type <> "Dependency" then
		Session.Output( "Error: Class [«"&currentElement.Stereotype&"» "& currentElement.Name &"] has association to class [" & elementOnOppositeSide.Name & "] that is not a composition on "& elementOnOppositeSide.Name &"-side. [ISO19103:2015 Requirement 12]")									 
		globalErrorCounter = globalErrorCounter + 1 
	end if 

end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub name: checkMultiplicityOnNavigableEnds
' Author: Magnus Karge
' Date: 20170110 
' Purpose:  sub procedure to check if the given association properties fulfill the requirements regarding
'			multiplicity on navigable ends (navigable ends shall have multiplicity)
' 			
' @param[in]: 	theElement (EA.Element). The element that "ownes" the association to check
'				sourceEndNavigable (CharacterString). navigable setting on association's source end
'				targetEndNavigable (CharacterString). navigable setting on association's target end
'				sourceEndName (CharacterString). role name on association's source end
'				targetEndName (CharacterString). role name on association's target end
'				sourceEndCardinality (CharacterString). multiplicity on association's source end
'				targetEndCardinality (CharacterString). multiplicity on association's target end
sub checkMultiplicityOnNavigableEnds(theElement, sourceEndNavigable, targetEndNavigable, sourceEndName, targetEndName, sourceEndCardinality, targetEndCardinality, currentConnector)
	if sourceEndNavigable = "Navigable" and sourceEndCardinality = "" and currentConnector.Type <> "Dependency" then
		Session.Output( "Error: Class [«"&theElement.Stereotype&"» "& theElement.Name &"] \ association role [" & sourceEndName & "] lacks multiplicity. [ISO19103:2015 Requirement 10]") 
		globalErrorCounter = globalErrorCounter + 1 
	end if 
 								 
	if targetEndNavigable = "Navigable" and targetEndCardinality = "" and currentConnector.Type <> "Dependency" then
		Session.Output( "Error: Class [«"&theElement.Stereotype&"» "& theElement.Name &"] \ association role [" & targetEndName & "] lacks multiplicity. [ISO19103:2015 Requirement 10]") 
		globalErrorCounter = globalErrorCounter + 1 
	end if 
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub name: checkRoleNamesOnNavigableEnds
' Author: Magnus Karge
' Date: 20170110 
' Purpose:  sub procedure to check if the given association has role names on navigable ends 
'			(navigable ends shall have role names)
' 			
' @param[in]: 	theElement (EA.Element). The element that "ownes" the association to check
'				sourceEndNavigable (CharacterString). navigable setting on association's source end
'				targetEndNavigable (CharacterString). navigable setting on association's target end
'				sourceEndName (CharacterString). role name on association's source end
'				targetEndName (CharacterString). role name on association's target end
'				elementOnOppositeSide (EA.Element). The element on the opposite side of the association to check
sub checkRoleNamesOnNavigableEnds(theElement, sourceEndNavigable, targetEndNavigable, sourceEndName, targetEndName, elementOnOppositeSide, currentConnector)
	if sourceEndNavigable = "Navigable" and sourceEndName = "" and currentConnector.Type <> "Dependency" then
		Session.Output( "Error: Association between class [«"&theElement.Stereotype&"» "& theElement.Name &"] and class [«"&elementOnOppositeSide.Stereotype&"» "& elementOnOppositeSide.Name & "] lacks role name on navigable end on "& theElement.Name &"-side. [ISO19103:2015 Requirement 10]") 
		globalErrorCounter = globalErrorCounter + 1 
	end if 
 								 
	if targetEndNavigable = "Navigable" and targetEndName = "" and currentConnector.Type <> "Dependency" then
		Session.Output( "Error: Association between class [«"&theElement.Stereotype&"» "& theElement.Name &"] and class [«"&elementOnOppositeSide.Stereotype&"» "& elementOnOppositeSide.Name & "] lacks role name on navigable end on "& elementOnOppositeSide.Name &"-side. [ISO19103:2015 Requirement 10]") 
		globalErrorCounter = globalErrorCounter + 1 
	end if 
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub name: checkRoleNames
' Author: Magnus Karge
' Date: 20170110 
' Purpose:  sub procedure to check if a given association's role names start with lower case (19103:2015 recommendation 11)
'			(note:  navigable ends shall have role names [ISO19103:2015 requirement 11]) 
' 			
' @param[in]: 	theElement (EA.Element). The element that "ownes" the association to check
'				sourceEndName (CharacterString). role name on association's source end
'				targetEndName (CharacterString). role name on association's target end
'				elementOnOppositeSide (EA.Element). The element on the opposite side of the association to check
sub checkRoleNames(theElement, sourceEndName, targetEndName, elementOnOppositeSide)
	if globalLogLevelIsWarning then
		if not sourceEndName = "" and not Left(sourceEndName,1) = LCase(Left(sourceEndName,1)) then 
			Session.Output("Warning: Role name [" & sourceEndName & "] on association end connected to class ["& theElement.Name &"] should start with lowercase letter. [ISO19103:2015 Recommendation 11]") 
			globalWarningCounter = globalWarningCounter + 1 
		end if 

		if not (targetEndName = "") and not (Left(targetEndName,1) = LCase(Left(targetEndName,1))) then 
			Session.Output("Warning: Role name [" & targetEndName & "] on association end connected to class ["& elementOnOppositeSide.Name &"] should start with lowercase letter. [ISO19103:2015 Recommendation 11]") 
			globalWarningCounter = globalWarningCounter + 1 
		end if 
	end if
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub name: checkUniqueFeatureTypeNames
' Author: Magnus Karge
' Date: 20170110 
' Purpose:  sub procedure to check if a given FeatureType's name is unique within the applicationSchema
''			(the class name shall be unique within the application schema [ISO19109:2015 /req/uml/feature]) 
' 			
' @param[in]: 	none - uses only global variables FeatureTypeNames and FeatureTypeElementIDs
sub checkUniqueFeatureTypeNames()
	'iterate over elements in the  name and id arrays until the arrays are empty
	DO UNTIL FeatureTypeNames.count = 0 AND FeatureTypeElementIDs.count = 0 				
		dim temporaryFeatureTypeArray
		set temporaryFeatureTypeArray = CreateObject("System.Collections.ArrayList")
		dim ftNameToCompare
		ftNameToCompare = FeatureTypeNames.Item(0)
		dim ftElementID
		ftElementID = FeatureTypeElementIDs.Item(0)
		dim initialElementToAdd AS EA.Element
		set initialElementToAdd = Repository.GetElementByID(ftElementID)
		temporaryFeatureTypeArray.Add(initialElementToAdd)
		FeatureTypeNames.RemoveAt(0)
		FeatureTypeElementIDs.RemoveAt(0)
		dim elementNumber
		for elementNumber = FeatureTypeNames.count - 1 to 0 step -1
			dim currentName
			currentName = FeatureTypeNames.Item(elementNumber)
			if currentName = ftNameToCompare then
				dim currentElementID
				currentElementID = FeatureTypeElementIDs.Item(elementNumber)
				dim additionalElementToAdd AS EA.Element
				set additionalElementToAdd = Repository.GetElementByID(currentElementID) 
				'add element with matching name to the temporary array and remove its name and ID from the name and id array
				temporaryFeatureTypeArray.Add(additionalElementToAdd)
				FeatureTypeNames.RemoveAt(elementNumber)
				FeatureTypeElementIDs.RemoveAt(elementNumber)
			end if
		next
		
		'generate error messages according to content of the temporary array
		dim tempStoredFeatureType AS EA.Element
		if temporaryFeatureTypeArray.count > 1 then
			Session.Output("Error: Found nonunique names for the following classes. [ISO19109:2015 /req/uml/feature] & ISO19109:2015 [req/general/feature]")
			'counting one error per name conflict (not one error per class with nonunique name)
			globalErrorCounter = globalErrorCounter + 1
			for each tempStoredFeatureType in temporaryFeatureTypeArray
				dim theFeatureTypePackage AS EA.Package
				set theFeatureTypePackage = Repository.GetPackageByID(tempStoredFeatureType.PackageID) 
				dim theFeatureTypePackageName
				theFeatureTypePackageName = theFeatureTypePackage.Name
				Session.Output("   Class [«"&tempStoredFeatureType.Stereotype&"» "&tempStoredFeatureType.Name&"] in package ["&theFeatureTypePackageName& "]")
			next	
		end if
		
		'get the element with the first elementID and move it to the temporary array
	LOOP
	
 end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Script Name: checkInstantiable
' Author: Åsmund Tjora	
' Date: 170223
' Purpose: check that abstract classes has subclass within same application schema.  Check that no interface classes exists in application schema 
' Input parameter:  theClass  The class that is checked

sub checkInstantiable(theClass)
	if (UCase(theClass.Stereotype) = "INTERFACE" or theClass.Type = "Interface") then
		Session.Output("Error:  Class [«" &theClass.Stereotype& "» " &theClass.Name& "].  Interface stereotype for classes is not allowed in ApplicationSchema. [ISO19109:2015 /req/uml/structure]")
		globalErrorCounter = globalErrorCounter + 1
	end if
	if theClass.Abstract = "1" then
		dim connector as EA.Connector
		dim hasSpecializations
		dim specInSameApplicationSchema
		hasSpecializations=false
		specInSameApplicationSchema=false
		for each connector in theClass.Connectors
			if connector.Type = "Generalization" then
				if theClass.ElementID = connector.SupplierID then
					hasSpecializations=true					
					dim subClass as EA.Element
					dim pkID
					set subClass = Repository.GetElementByID(connector.ClientID)
					for each pkID in globalPackageIDList
						if subClass.PackageID = pkID then specInSameApplicationSchema=true
					next
				end if
			end if
		next
		if not (hasSpecializations and specInSameApplicationSchema) then
			Session.Output("Error: Class [«" &theClass.Stereotype& "» " &theClass.Name& "]. Abstract class does not have any instantiable specializations in the ApplicationSchema. [ISO19109:2015 /req/uml/structure]")
			globalErrorCounter = globalErrorCounter + 1
		end if
	end if
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

'------------------------------------------------------------START-------------------------------------------------------------------------------------------

' Script Name: checkPackageDependency
' Author: Åsmund Tjora, Magnus Karge
' Date: 170329
' Purpose: Check that elements in external packages are accessible through package dependencies.  Check that dependency diagrams show these dependencies. 
' Input parameter:  thePackage:  Package to be checked

sub checkPackageDependency(thePackage)

	'dim packageDependencies - NOT IN USE - GLOBAL VARIABLE USED INSTEAD
	'set packageDependencies=CreateObject("System.Collections.ArrayList")
	'packageDependenciesShown - List of package dependencies shown in package diagrams
	dim packageDependenciesShown
	set packageDependenciesShown=CreateObject("System.Collections.ArrayList")

	'get package dependencies declared in ApplicationSchema model
	'call findPackageDependencies(thePackage.Element, packageDependencies) - NOT IN USE - GLOBAL VARIABLE USED INSTEAD
	'get package dependencies actually shown in package diagrams in model
	call findPackageDependenciesShown(thePackage, packageDependenciesShown)
	
	'---
	'compare "real" dependencies made by referencing out-of-package elements with
	'package dependencies declared in model and dependencies shown in diagrams
	dim packageElementID
	dim investigatedPackage
	dim investigatedElement
	dim elementID
	dim package as EA.Package
	dim packageID
	dim i
	' do stuff to compare the packages containing actual (element) references, the declared dependencies and the shown dependencies
	for i = 0 to globalListPackageIDsOfPackagesToBeReferenced.Count-1
		packageID = globalListPackageIDsOfPackagesToBeReferenced(i)
		set package = Repository.GetPackageByID(packageID)
		packageElementID=package.Element.ElementID
		if not packageDependenciesShown.Contains(packageElementID) then
			elementID = globalListClassifierIDsOfExternalReferencedElements(i)
			set investigatedPackage=Repository.GetElementByID(packageElementID)
			set investigatedElement=Repository.GetElementByID(elementID)
	'		if not globalListPackageElementIDsOfPackageDependencies.Contains(packageElementID) then
	'			Session.Output("Error: Use of element " & investigatedElement.Name & " from package " & investigatedPackage.Name & " is not listed in model dependencies [/req/uml/integration]")
	'		else
			Session.Output("Error: Dependency on package [" & investigatedPackage.Name & "] needed for the use of element [" & investigatedElement.Name & "] is not shown in any package diagram [ISO19103:2015 requirement 17][ISO19103:2015 requirement 21]")
			globalErrorCounter=globalErrorCounter+1 
	'		end if
		end if
	next
	
	'check that dependencies are between ApplicationSchema packages.
	for each packageElementID in globalListPackageElementIDsOfPackageDependencies
		set investigatedPackage=Repository.GetElementByID(packageElementID)
		if globalRuleSet19109 and (not UCase(investigatedPackage.Stereotype)="APPLICATIONSCHEMA") then
			if globalLogLevelIsWarning then
				Session.Output("Warning: Dependency to package [«" & investigatedPackage.Stereotype & "» " & investigatedPackage.Name & "] found.  Dependencies shall only be to ApplicationSchema packages or Standard schemas. Ignore this warning if [«" & investigatedPackage.Stereotype & "» " & investigatedPackage.Name & "] is a standard schema [ISO19109:2015 req/uml/integration]")
				globalWarningCounter = globalWarningCounter + 1
			end if
		end if
	next
end sub

sub findPackageDependencies(thePackageElement)
	dim connectorList as EA.Collection
	dim packageConnector as EA.Connector
	dim dependee as EA.Element
	
	set connectorList=thePackageElement.Connectors
	
	for each packageConnector in connectorList
		if packageConnector.Type="Usage" or packageConnector.Type="Package" or packageConnector.Type="Dependency" then
			if thePackageElement.ElementID = packageConnector.ClientID then
				set dependee = Repository.GetElementByID(packageConnector.SupplierID)
				globalListPackageElementIDsOfPackageDependencies.Add(dependee.ElementID)
				'call findPackageDependencies(dependee)
			end if
		end if
	next
end sub

sub findPackageDependenciesShownRecursive(diagram, investigatedPackageElementID, dependencyList)
	'recursively traverse the packages in a diagram in order to get the full dependencyList.
	dim elementList
	set elementList=diagram.DiagramObjects
	dim diagramElement
	dim modelElement
	dim linkList
	set linkList=diagram.diagramLinks
	dim diagramLink
	dim modelLink
	
	for each diagramLink in linkList
		set modelLink=Repository.GetConnectorByID(diagramLink.ConnectorID)
		if modelLink.Type = "Package" or modelLink.Type = "Usage" or modelLink.Type="Dependency" then
			if modelLink.ClientID = investigatedPackageElementID then
				dim supplier
				dim client
				set supplier = Repository.GetElementByID(modelLink.SupplierID)
				set client = Repository.GetElementByID(modelLink.ClientID)
				dependencyList.Add(modelLink.SupplierID)
				'call findPackageDependenciesShownRecursive(diagram, modelLink.SupplierID, dependencyList)
				if diagramLink.IsHidden and globalLogLevelIsWarning then
					Session.Output("Warning: Diagram [" & diagram.Name &"] contains hidden dependency link between elements " & supplier.Name & " and " & client.Name & ". [ISO19103:2015 requirement 17][ISO19103:2015 requirement 21]")
					globalWarningCounter=globalWarningCounter+1
				end if
			end if
		end if
	next
end sub

sub getAllPackageDiagramIDs(thePackage, packageDiagramIDList)
	
	dim diagramList
	set diagramList=thePackage.Diagrams
	dim subPackageList
	set subPackageList=thePackage.Packages
	dim diagram
	dim subPackage
	
	for each diagram in diagramList
		'Note: It is possible to generate package diagrams in other diagram types (e.g. class diagarams)
		'The check for diagram type is therefore disabled.
		'if diagram.Type="Package" then
			packageDiagramIDList.Add(diagram.DiagramID)
			
		'end if
	next
	for each subPackage in subPackageList
		call getAllPackageDiagramIDs(subPackage, packageDiagramIDList)
	next
end sub
	

sub findPackageDependenciesShown(thePackage, dependencyList)
	dim thePackageElementID
	thePackageElementID = thePackage.Element.ElementID
	dim packageDiagramIDList
	set packageDiagramIDList=CreateObject("System.Collections.ArrayList")
	dim diagramID
	dim diagram
	dim subPackage

'	set diagramList=thePackage.Diagrams
'	set subPackageList=thePackage.Packages

	call getAllPackageDiagramIDs(thePackage, packageDiagramIDList)

	for each diagramID in packageDiagramIDList
		set diagram=Repository.GetDiagramByID(diagramID)
		call findpackageDependenciesShownRecursive(diagram, thePackageElementID, dependencyList)
	next	
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Function Name: findPackagesToBeReferenced
' Author: Magnus Karge
' Date: 20170303
' Purpose: 	to collect the IDs of all packages the applicationSchema package is dependent on
'			populates globalListPackageIDsOfPackagesToBeReferenced
' Input parameter:  none, uses global variable globalListClassifierIDsOfExternalReferencedElements

sub findPackagesToBeReferenced()
	dim externalReferencedElementID
	
	dim currentExternalElement as EA.Element
	dim arrayCounter
	
	for each externalReferencedElementID in globalListClassifierIDsOfExternalReferencedElements
		set currentExternalElement = Repository.GetElementByID(externalReferencedElementID)
		dim parentPackageID
		parentPackageID = currentExternalElement.PackageID 'here the parentPackageID is the ID of the package containing the external element
		
		'temporal variable containing list of packageIDs of AppSchemaPackages in package hierarchy upwards from the external referenced element
		dim tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy
		set tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy=CreateObject("System.Collections.ArrayList")
		
		'temporal variable containing list of packageIDs of referenced packages in package hierarchy upwards from the external referenced element
		dim tmpListPackageIDsOfReferencedPackagesFoundInHierarchy
		set tmpListPackageIDsOfReferencedPackagesFoundInHierarchy=CreateObject("System.Collections.ArrayList")
		
		dim foundApplicationSchemaInPackageHierarchy
		foundApplicationSchemaInPackageHierarchy = false
		dim foundReferencedPackageInHierarchy
		foundReferencedPackageInHierarchy = false
		
		dim parentPackageIsApplicationSchema
		parentPackageIsApplicationSchema = false
		dim parentPackage as EA.Package
		if (not parentPackageID = 0) then 'meaning that there is a package
			set parentPackage = Repository.GetPackageByID(parentPackageID)
			'check if parentPackage is package and not model
			if (not parentPackage.IsModel) then
				if UCase(parentPackage.Element.Stereotype)="APPLICATIONSCHEMA" then
					parentPackageIsApplicationSchema = true
					tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy.Add(parentPackageID)
					foundApplicationSchemaInPackageHierarchy = true
				end if
			end if	
			
			'check if parentPackage has dependency from the startpackage
			if globalListPackageElementIDsOfPackageDependencies.contains(parentPackage.Element.ElementID) then
				tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.add(parentPackageID)
				Session.Output("Found dependency from start package to: "&parentPackage.Name)
				foundReferencedPackageInHierarchy = true
			end if
			
		end if
		
		dim tempPackageIDOfPotentialPackageToBeReferenced
		tempPackageIDOfPotentialPackageToBeReferenced = parentPackageID
		
		
		
		'go recursively upwards in package hierarchy until finding a "model-package" or finding no package at all (meaning packageID = 0) or finding a package with stereotype applicationSchema
		do while ((not parentPackageID = 0) and (not parentPackage.IsModel)) 
			parentPackageID = parentPackage.ParentID 'here the new parentPackageID is the ID of the package containing the parent package
			set parentPackage = Repository.GetPackageByID(parentPackageID)
						
			if (not parentPackage.IsModel) then 
				if UCase(parentPackage.Element.Stereotype)="APPLICATIONSCHEMA" then
					parentPackageIsApplicationSchema = true
					tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy.Add(parentPackageID)
					tempPackageIDOfPotentialPackageToBeReferenced = parentPackageID
					foundApplicationSchemaInPackageHierarchy = true
				end if
				'check if parentPackage has dependency from the start package
				if globalListPackageElementIDsOfPackageDependencies.contains(parentPackage.Element.ElementID) then
					tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.add(parentPackageID)
					Session.Output("Found dependency from start package to: "&parentPackage.Name)
					foundReferencedPackageInHierarchy = true
				end if

			end if
			
		loop
	
		'add the temporal package ID to the global list
		'the temporal package ID is either the package containing the external element
		'or the first package found upwards in the package hierarchy with stereotype applicationSchema
		if not foundReferencedPackageInHierarchy then
			globalListPackageIDsOfPackagesToBeReferenced.add(tempPackageIDOfPotentialPackageToBeReferenced)
			
		end if
		
		
		if globalRuleSet19109 and tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy.count = 0 and tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.count = 0 then
			Session.Output("Error: Missing dependency for package ["& Repository.GetPackageByID(tempPackageIDOfPotentialPackageToBeReferenced).Name &"] (or any of its superpackages) containing external referenced class [" &currentExternalElement.Name& "] [ISO19109:2015 /req/uml/integration]")
			globalErrorCounter = globalErrorCounter + 1
		end if
		if globalRuleSet19109 and tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy.count > 0 and tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.count = 0 then
			Session.Output("Error: Missing dependency for package [<<applicationSchema>> "& Repository.GetPackageByID(tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy(0)).Name &"] containing external referenced class [" &currentExternalElement.Name& "] [ISO19109:2015 /req/uml/integration]")
			globalErrorCounter = globalErrorCounter + 1
		end if
		
		if tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy.count > 0 and tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.count > 0 then
			'TODO does only check the first applicationSchema package found --> to be improved
			dim packageIDOfFirstAppSchemaPackageFoundInHierarchy
			packageIDOfFirstAppSchemaPackageFoundInHierarchy = tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy(0)
			dim packageIDOfReferencedPackage
			if globalRuleSet19109 and (not tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.contains(packageIDOfFirstAppSchemaPackageFoundInHierarchy)) then
				Session.Output("Error: Missing dependency for package [<<applicationSchema>> "& Repository.GetPackageByID(tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy(0)).Name &"] containing external referenced class [" &currentExternalElement.Name& "] [ISO19109:2015 /req/uml/integration]")
				Session.Output("       Please exchange the modelled dependency to the following package(s) because of an existing applicationSchema package in the package hierarchy:")
				globalErrorCounter = globalErrorCounter + 1
				for each packageIDOfReferencedPackage in tmpListPackageIDsOfReferencedPackagesFoundInHierarchy
					Session.Output("       Exchange dependency related to package ["& Repository.GetPackageByID(packageIDOfReferencedPackage).Name &"] with dependency to package [<<applicationSchema>> "& Repository.GetPackageByID(tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy(0)).Name &"]")
					
				next
			elseif globalRuleSet19109 and tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.contains(packageIDOfFirstAppSchemaPackageFoundInHierarchy) and tmpListPackageIDsOfReferencedPackagesFoundInHierarchy.count > 1 then
				Session.Output("Error: Found redundant dependency related to package [<<applicationSchema>> "& Repository.GetPackageByID(tmpListPackageIDsOfAppSchemaPackagesFoundInHierarchy(0)).Name &"] containing external referenced class [" &currentExternalElement.Name& "] [ISO19109:2015 /req/uml/integration]")
				Session.Output("       Please remove additional modelled dependency to the following package(s) in the same package hierarchy:")
				globalErrorCounter = globalErrorCounter + 1
				for each packageIDOfReferencedPackage in tmpListPackageIDsOfReferencedPackagesFoundInHierarchy
					if not packageIDOfFirstAppSchemaPackageFoundInHierarchy = packageIDOfReferencedPackage then
						Session.Output("       Remove dependency related to package ["& Repository.GetPackageByID(packageIDOfReferencedPackage).Name &"]")
					end if
				next
			
			end if
		end if
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Function Name: getElementIDsOfExternalReferencedElements
' Author: Magnus Karge
' Date: 20170228
' Purpose: 	to collect the IDs of all elements not part of the applicationSchema package but referenced from elements in
'			thePackage or subpackages (e.g. via associations or types of attributes) 
'			populates globalListClassifierIDsOfExternalReferencedElements
' Input parameter:  thePackage:EA.Package, uses global variable globalListAllClassifierIDsInApplicationSchema

sub getElementIDsOfExternalReferencedElements(thePackage)
			
	dim elementsInPackage as EA.Collection
	set elementsInPackage = thePackage.Elements
	
	dim subpackages as EA.Collection 
	set subpackages = thePackage.Packages 'collection of packages that belong to thePackage	
			
	'Navigate the package collection and call the getElementIDsOfExternalElements sub for each of the packages 
	dim p 
	for p = 0 to subpackages.Count - 1 
		dim currentPackage as EA.Package 
		set currentPackage = subpackages.GetAt( p ) 
		getElementIDsOfExternalReferencedElements(currentPackage) 
	next 
 			 
 	'------------------------------------------------------------------ 
	'---ELEMENTS--- 
	'------------------------------------------------------------------		 
 			 
	' Navigate the elements collection, pick the classes, find the definitions/notes and do sth. with it 
	'Session.Output( " number of elements in package: " & elements.Count) 
	dim e 
	for e = 0 to elementsInPackage.Count - 1 
		dim currentElement as EA.Element 
		set currentElement = elementsInPackage.GetAt( e ) 
		
		'check all attributes
		dim listOfAttributes as EA.Collection
		set listOfAttributes = currentElement.Attributes
		dim a
		for a = 0 to listOfAttributes.Count - 1 
			dim currentAttribute as EA.Attribute
			set currentAttribute = listOfAttributes.GetAt(a)
			'check if classifier id is connected to a base type - not a primitive type (not 0) and if it 
			'is part of globalListAllClassifierIDsInApplicationSchema
			if not currentAttribute.ClassifierID = 0 AND not globalListAllClassifierIDsInApplicationSchema.contains(currentAttribute.ClassifierID) then
				'Session.Output( "!DEBUG! ID [" & currentAttribute.ClassifierID & "] not in list globalListAllClassifierIDsInApplicationSchema and not 0") 
				if not globalListClassifierIDsOfExternalReferencedElements.Contains(currentAttribute.ClassifierID) then
					'add to list if not contained already
					globalListClassifierIDsOfExternalReferencedElements.Add(currentAttribute.ClassifierID)
					'Session.Output( "!DEBUG! ID [" & currentAttribute.ClassifierID & "] added to globalListClassifierIDsOfExternalReferencedElements") 
				else
					'Session.Output( "!DEBUG! ID [" & currentAttribute.ClassifierID & "] already in list globalListClassifierIDsOfExternalReferencedElements") 
				end if
			else 
				'Session.Output( "!DEBUG! ID [" & currentAttribute.ClassifierID & "] already in list globalListAllClassifierIDsInApplicationSchema or 0") 
			end if
		next	
		
		'check all connectors
		dim listOfConnectors as EA.Collection
		set listOfConnectors = currentElement.Connectors
		dim c
		for c = 0 to listOfConnectors.Count - 1 
			dim currentConnector as EA.Connector
			set currentConnector = listOfConnectors.GetAt(c)
			'check if this element is on source side of connector - if not ignore (could be external connectors pointing to the element)
			' and if the id of the element on supplier side of the connector is in globalListAllClassifierIDsInApplicationSchema
			'in addition, realizations will be ignored
			if currentElement.ElementID = currentConnector.ClientID AND not currentConnector.Type = "Realisation" AND not globalListAllClassifierIDsInApplicationSchema.contains(currentConnector.SupplierID) then
				if not globalListClassifierIDsOfExternalReferencedElements.contains(currentConnector.SupplierID) then
					globalListClassifierIDsOfExternalReferencedElements.Add(currentConnector.SupplierID)
					'Session.Output( "!DEBUG! ID [" & currentConnector.SupplierID & "] added to globalListClassifierIDsOfExternalReferencedElements") 
				else
					'Session.Output( "!DEBUG! ID [" & currentConnector.SupplierID & "] already in list globalListClassifierIDsOfExternalReferencedElements") 
				end if
			else
				'Session.Output( "!DEBUG! ID [" & currentConnector.SupplierID & "] already in list globalListAllClassifierIDsInApplicationSchema") 
			end if
		next	
		
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'Sub name: 		CheckSubPackageStereotype
'Author: 		Åsmund Tjora
'Date: 			20170228
'Purpose: 		Check the stereotypes of sub packages.  Only the root shall have stereotype "ApplicationSchema" 
'Parameters:	rootPackage  The package to be added to the list and investigated for subpackages
' 
sub CheckSubPackageStereotype(rootPackage)
	dim subPackageList as EA.Collection
	dim subPackage as EA.Package
	set subPackageList = rootPackage.Packages
	
	for each subPackage in subPackageList
		if UCase(subPackage.Element.Stereotype)="APPLICATIONSCHEMA" then
			Session.Output("Error: Package [«" &subPackage.Element.Stereotype& "» " &subPackage.Name& "]. Package with stereotype ApplicationSchema cannot contain subpackages with stereotype ApplicationSchema. [ISO19109:2015 /req/uml/integration]")
			globalErrorCounter = globalErrorCounter + 1
		end if	
	next
end sub
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: FindInvalidElementsInPackage19109Rules
' Author: Kent Jonsrud, Magnus Karge...
' Purpose: Main loop iterating all elements in the selected package and conducting tests on those elements. All tests based on 19109 rules.

sub FindInvalidElementsInPackage19109Rules(package) 
			
 	dim elements as EA.Collection 
 	set elements = package.Elements 'collection of elements that belong to this package (classes, notes... BUT NO packages) 
 	Dim myDictionary 
 	dim errorsInFunctionTests 
 			 
 	'check package definition 
 	CheckDefinition(package) 
			 
	'Iso 19103 Requirement 15 - known stereotypes for packages. - warning if not a standardised stereotype
	'this is not implemented as an error since there can be reasons for new stereotypes with different meaning than the standardised stereotypes
	if UCase(package.element.Stereotype) <> "APPLICATIONSCHEMA" and UCase(package.element.Stereotype) <> "LEAF" and UCase(package.element.Stereotype) <> "" then
		if globalLogLevelIsWarning then
			Session.Output("Warning: Unknown package stereotype: [«" &package.element.Stereotype& "» " &package.Name& "]. [ISO19103 Requirement 15]")
			globalWarningCounter = globalWarningCounter + 1
		end if	
	end if

	call checkSubPackageStereotype(package)
	
	'Iso 19103 Requirement 16 - unique (NC?)Names on subpackages within the package.
	if ClassAndPackageNames.IndexOf(UCase(package.Name),0) <> -1 then
		Session.Output("Error: Package [" &startPackageName& "] has non-unique subpackage name ["&package.Name&"]. [ISO19103:2015 Requirement 16]")				
		globalErrorCounter = globalErrorCounter + 1 
	end if

	ClassAndPackageNames.Add UCase(package.Name)

	'check if the package name is written correctly according to [ISO19103:2015 recommendation 11]
	checkElementName(package)
 			 
	dim packageTaggedValues as EA.Collection 
	set packageTaggedValues = package.Element.TaggedValues 
 			
	'only for applicationSchema packages: 
	'iterate the tagged values collection and check if the applicationSchema package has a tagged value "language", "designation" or "definition" with correct pattern [ISO19109:2015 /req/multi-lingual/package]
	Call checkTVLanguageAndDesignation (package.Element, "language") 
	Call checkTVLanguageAndDesignation (package.Element, "designation")
	Call checkTVLanguageAndDesignation (package.Element, "definition")
	'iterate the tagged values collection and check if the applicationSchema package has a tagged value "version" with any content [/req/uml/packaging ]	
	Call checkValueOfTVVersion( package.Element , "version" ) 
	
	dim packages as EA.Collection 
	set packages = package.Packages 'collection of packages that belong to this package	
			
	'Navigate the package collection and call the FindInvalidElementsInPackage19109Rules function for each of them 
	dim p 
	for p = 0 to packages.Count - 1 
		dim currentPackage as EA.Package 
		set currentPackage = packages.GetAt( p ) 
		FindInvalidElementsInPackage19109Rules(currentPackage) 
				
		'constraints 
		dim constraintPCollection as EA.Collection 
		set constraintPCollection = currentPackage.Element.Constraints 
 			 
		if constraintPCollection.Count > 0 then 
			dim constraintPCounter 
			for constraintPCounter = 0 to constraintPCollection.Count - 1 					 
				dim currentPConstraint as EA.Constraint		 
				set currentPConstraint = constraintPCollection.GetAt(constraintPCounter) 
								
				'check if the package got constraints that lack name or definition ([ISO19109:2015 /req/uml/constraint])								
				Call checkConstraint(currentPConstraint, currentPackage)

			next
		end if	
	next 
 			 
 	'------------------------------------------------------------------ 
	'---ELEMENTS--- 
	'------------------------------------------------------------------		 
 			 
	' Navigate the elements collection, pick the classes, find the definitions/notes and do sth. with it 
	'Session.Output( " number of elements in package: " & elements.Count) 
	dim i 
	for i = 0 to elements.Count - 1 
		dim currentElement as EA.Element 
		set currentElement = elements.GetAt( i ) 
				
						
		if (currentElement.Type="Class" or currentElement.Type="Interface") then
			call checkInstantiable(currentElement)
		end if
				
		'Is the currentElement of type Class and stereotype codelist or enumeration, check the initial values are numeric or not ([ISO19103:2015 Recommendation 1])
		if ((currentElement.Type = "Class") and (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION") Or currentElement.Type = "Enumeration") then
			call checkNumericinitialValues(currentElement)
		end if

		' check if inherited stereotypes are all the same
		Call requirement14(currentElement)
		' check that no class inherits from a class named GM_Object or TM_Object
		Call reqGeneralFeature(currentElement, currentElement)
		' ---ALL CLASSIFIERS---
		'Iso 19103 Requirement 16 - unique NCNames of all properties within the classifier.
		'Inherited properties  also included, strictly not an error situation but implicit redefinition is not well supported anyway
		if currentElement.Type = "Class" or currentElement.Type = "DataType" or currentElement.Type = "Enumeration" or currentElement.Type = "Interface" then
			if ClassAndPackageNames.IndexOf(UCase(currentElement.Name),0) <> -1 then
				Session.Output("Error: Class [«" &currentElement.Stereotype& "» "&currentElement.Name&"] in package: [" &package.Name& "] has non-unique name. [ISO19103:2015 Requirement 16]")				
				globalErrorCounter = globalErrorCounter + 1 
			end if

			ClassAndPackageNames.Add UCase(currentElement.Name)

			call requirement16UniqueNCname(currentElement)
		else
			' ---OTHER ARTIFACTS--- Do their names also need to be tested for uniqueness? (need to be different?)
			if currentElement.Type <> "Note" and currentElement.Type <> "Text" and currentElement.Type <> "Boundary" then
				if ClassAndPackageNames.IndexOf(UCase(currentElement.Name),0) <> -1 then
					Session.Output("Debug: Unexpected unknown element with non-unique name [«" &currentElement.Stereotype& "» " &currentElement.Name& "]. EA-type: [" &currentElement.Type& "]. [ISO19103:2015 Requirement 16]")
					'This test is dependent on where the artifact is in the test sequence 
				end if
			end if
		end if
				
		'constraints 
		dim constraintCollection as EA.Collection 
		set constraintCollection = currentElement.Constraints 

		if constraintCollection.Count > 0 then 
			dim constraintCounter 
			for constraintCounter = 0 to constraintCollection.Count - 1 					 
				dim currentConstraint as EA.Constraint		 
				set currentConstraint = constraintCollection.GetAt(constraintCounter) 
							
				'check if the constraints lack name or definition ([ISO19109:2015 /req/uml/constraint])
				Call checkConstraint(currentConstraint, currentElement)

			next
		end if		



		'If the currentElement is of type Class, Enumeration or DataType continue conducting some tests. If not continue with the next element. 
		if currentElement.Type = "Class" Or currentElement.Type = "Enumeration" Or currentElement.Type = "DataType" then 
 									 
			'------------------------------------------------------------------ 
			'---CLASSES---ENUMERATIONS---DATATYPE  								'   classifiers ???
			'------------------------------------------------------------------		 
			
			'add name and elementID of the featureType (class, datatype, enumeration with stereotype <<featureType>>) to the related array variables in order to check if the names are unique
			if UCase(currentElement.Stereotype) = "FEATURETYPE" then
				FeatureTypeNames.Add(currentElement.Name)
				FeatureTypeElementIDs.Add(currentElement.ElementID)
			end if
			
			'Iso 19103 Requirement 6 - NCNames in codelist codes.
			if (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" Or currentElement.Type = "Enumeration") then
				call requirement6(currentElement)
			end if

			'Iso 19103 Requirement 7 - definition of codelist codes.
			if (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" or currentElement.Type = "Enumeration") then
				call requirement7CodeDefinition(currentElement)
			end if
	
			'Iso 19103 Requirement 15 - known stereotypes for classes - warning if not a standardised stereotype
			'this is not implemented as an error since there can be reasons for new stereotypes with different meaning than the standardised stereotypes
			
			if currentElement.Stereotype = "" Or UCase(currentElement.Stereotype) = "FEATURETYPE"  Or UCase(currentElement.Stereotype) = "DATATYPE" Or UCase(currentElement.Stereotype) = "UNION" or UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" Or UCase(currentElement.Stereotype) = "ESTIMATED" or UCase(currentElement.Stereotype) = "MESSAGETYPE"  Or UCase(currentElement.Stereotype) = "INTERFACE" Or currentElement.Type = "Enumeration" then
			else
				if globalLogLevelIsWarning then
					Session.Output("Warning: Class [«" &currentElement.Stereotype& "» " &currentElement.Name& "] has unknown stereotype. [ISO19103 Requirement 15]")
					globalWarningCounter = globalWarningCounter + 1
				end if	
			end if

			'Iso 19103 Requirement 15 - known stereotypes for attributes. 
			call checkKnownStereotypes(currentElement)

			'Iso 19109 Requirement /req/uml/profile - well known types. Including Iso 19103 Requirements 22 and 25
			if (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" Or currentElement.Type = "Enumeration") then
				'codelist code type shall be empty, <none> or <undefined>
			else
				call reqUmlProfile(currentElement)
			end if

			'Iso 19103 Requirement 18 - each classifier must show all its (inherited) properties together in at least one diagram.
			call requirement18(currentElement)

			'check if there is a definition for the class element (call CheckDefinition function) 
			CheckDefinition(currentElement) 
 										 
			'initialize the global variable startClass which is needed in subroutine findMultipleInheritance 
			set startClass = currentElement 

 					 
			'check the structure of the value for tag values: designation, description and definition [ISO19109:2015 /req/multi-lingual/feature]
			if UCase(currentElement.Stereotype) = "FEATURETYPE" then 
				Call structurOfTVforElement( currentElement, "description")
				Call structurOfTVforElement( currentElement, "designation") 
				Call structurOfTVforElement( currentElement, "definition")
			end if 
		
			'check if the class name is written correctly according to [ISO19103:2015 recommendation 11] (name starts with capital letter)
			checkElementName(currentElement)
 											
			if ((currentElement.Type = "Class") and (UCase(currentElement.Stereotype) = "CODELIST")) then
				'Check if an external codelist has a codeList tag that is not empty [ISO19103:2015 Recommendation 4]
				Call CheckCodelistTV(currentElement, "codeList")
			end if 
					
					
			dim stereotype
			stereotype = currentElement.Stereotype 
 					
				
			'------------------------------------------------------------------ 
			'---ATTRIBUTES--- 
			'------------------------------------------------------------------					 
 						 
			' Retrieve all attributes for this element 
			dim attributesCollection as EA.Collection 
			set attributesCollection = currentElement.Attributes 
 			 
			if attributesCollection.Count > 0 then 
				dim n 
				for n = 0 to attributesCollection.Count - 1 					 
					dim currentAttribute as EA.Attribute		 
					set currentAttribute = attributesCollection.GetAt(n) 
					'check if the attribute has a definition									 
					'Call the subfunction with currentAttribute as parameter 
					CheckDefinition(currentAttribute) 
					'check the structure of the value for tagged values: designation, description and definition [ISO19109 /req/multi-lingual/feature]
					Call structurOfTVforElement( currentAttribute, "description")
					Call structurOfTVforElement( currentAttribute, "designation")
					Call structurOfTVforElement( currentAttribute, "definition") 
															
					'check if the attribute's name is written correctly according to [ISO19103:2015 recommendation 11], meaning attribute name does not start with capital letter
					checkElementName(currentAttribute)
																								
					'constraints 
					dim constraintACollection as EA.Collection 
					set constraintACollection = currentAttribute.Constraints 
 			 
					if constraintACollection.Count > 0 then 
						dim constraintACounter 
						for constraintACounter = 0 to constraintACollection.Count - 1 					 
							dim currentAConstraint as EA.Constraint		 
							set currentAConstraint = constraintACollection.GetAt(constraintACounter) 
									
							'check if the constraints lacks name or definition ([ISO19109:2015 /req/uml/constraint])
							Call checkConstraint(currentAConstraint, currentAttribute)

						next
					end if		
				next 
			end if	 
 					 
			'------------------------------------------------------------------ 
			'---ASSOCIATIONS--- 
			'------------------------------------------------------------------ 
 						 
			'retrieve all associations for this element 
			dim connectors as EA.Collection 
			set connectors = currentElement.Connectors 
 					
			'iterate the connectors 
			'Session.Output("Found " & connectors.Count & " connectors for featureType " & currentElement.Name) 
			dim connectorsCounter 
			for connectorsCounter = 0 to connectors.Count - 1 
				dim currentConnector as EA.Connector 
				set currentConnector = connectors.GetAt( connectorsCounter ) 
							
				if currentConnector.Type = "Aggregation" or currentConnector.Type = "Association" then
								
					'target end 
					dim supplierEnd as EA.ConnectorEnd
					set supplierEnd = currentConnector.SupplierEnd
	
					Call structurOfTVforElement(supplierEnd, "description") 
					Call structurOfTVforElement(supplierEnd, "designation")
					Call structurOfTVforElement(supplierEnd, "definition")
									
					'source end 
					dim clientEnd as EA.ConnectorEnd
					set clientEnd = currentConnector.ClientEnd
									
					Call structurOfTVforElement(clientEnd, "description") 
					Call structurOfTVforElement(clientEnd, "designation")
					Call structurOfTVforElement(clientEnd, "definition")
				end if 		
 							
											
				dim sourceElementID 
				sourceElementID = currentConnector.ClientID 
				dim sourceEndNavigable  
				sourceEndNavigable = currentConnector.ClientEnd.Navigable 
				dim sourceEndName 
				sourceEndName = currentConnector.ClientEnd.Role 
				dim sourceEndDefinition 
				sourceEndDefinition = currentConnector.ClientEnd.RoleNote 
				dim sourceEndCardinality		 
				sourceEndCardinality = currentConnector.ClientEnd.Cardinality 
 							 
				dim targetElementID 
				targetElementID = currentConnector.SupplierID 
				dim targetEndNavigable  
				targetEndNavigable = currentConnector.SupplierEnd.Navigable 
				dim targetEndName 
				targetEndName = currentConnector.SupplierEnd.Role 
				dim targetEndDefinition 
				targetEndDefinition = currentConnector.SupplierEnd.RoleNote 
				dim targetEndCardinality 
				targetEndCardinality = currentConnector.SupplierEnd.Cardinality 
 							
				'if the current element is on the connectors client side conduct some tests 
				'(this condition is needed to make sure only associations where the 
				'source end is connected to elements within this package are  
				'checked. Associations with source end connected to elements outside of this 
				'package are possibly locked and not editable) 
				 							 
				dim elementOnOppositeSide as EA.Element 
				if currentElement.ElementID = sourceElementID and not currentConnector.Type = "Realisation" and not currentConnector.Type = "Generalization" then 
					
					'------------------------------------------------------------------ 
					'---'ASSOCIATION'S CONSTRAINTS--- 
					'----START-------------------------------------------------------------- 
					
					dim constraintRCollection as EA.Collection 
					set constraintRCollection = currentConnector.Constraints 
							
					if constraintRCollection.Count > 0 then 
						dim constraintRCounter 
						for constraintRCounter = 0 to constraintRCollection.Count - 1 					 
							dim currentRConstraint as EA.Constraint		 
							set currentRConstraint = constraintRCollection.GetAt(constraintRCounter) 
							'check if the connectors got constraints that lacks name or definition ([ISO19109:2015 /req/uml/constraint])
							Call checkConstraint(currentRConstraint, currentConnector)
						next
					end if 
					
					'----END-------------------------------------------------------------- 
					'---'ASSOCIATION'S CONSTRAINTS--- 
					'------------------------------------------------------------------ 
					
					set elementOnOppositeSide = Repository.GetElementByID(targetElementID) 
 								 
					'if the connector has a name (optional according to the rules), check if it starts with capital letter [ISO19103:2015 recommendation 11]
					call checkElementName(currentConnector)
					
					'check if elements on both sides of the association are classes with stereotype dataType or of element type DataType
					call checkDataTypeAssociation(currentElement, currentConnector, elementOnOppositeSide)
													
					'check if there is a definition on navigable ends (navigable association roles) of the connector 
					'Call the subfunction with currentConnector as parameter 
					CheckDefinition(currentConnector) 
 																								 
					'check if there is multiplicity on navigable ends ([ISO19103:2015 Requirement 10])
					call checkMultiplicityOnNavigableEnds(currentElement, sourceEndNavigable, targetEndNavigable, sourceEndName, targetEndName, sourceEndCardinality, targetEndCardinality, currentConnector)
					 
					'check if there are role names on navigable ends  ([ISO19103:2015 Requirement 10])
					call checkRoleNamesOnNavigableEnds(currentElement, sourceEndNavigable, targetEndNavigable, sourceEndName, targetEndName, elementOnOppositeSide, currentConnector)
																		 
					'check if role names on connector ends start with lower case (regardless of navigability) 
					call checkRoleNames(currentElement, sourceEndName, targetEndName, elementOnOppositeSide)
					
				end if 
			next 
 						 
			'------------------------------------------------------------------ 
			'---OPERATIONS--- 
			'------------------------------------------------------------------ 
 						 
			' Retrieve all operations for this element 
			dim operationsCollection as EA.Collection 
			set operationsCollection = currentElement.Methods 
 			 
			if operationsCollection.Count > 0 then 
				dim operationCounter 
				for operationCounter = 0 to operationsCollection.Count - 1 					 
					dim currentOperation as EA.Method		 
					set currentOperation = operationsCollection.GetAt(operationCounter) 
 								
					'check the structure of the value for tag values: designation, description and definition [ISO19109 /req/multi-lingual/feature]
					Call structurOfTVforElement(currentOperation, "description")
					Call structurOfTVforElement(currentOperation, "designation")
					Call structurOfTVforElement(currentOperation, "definition")
								
					'check if the operations's name starts with lower case 
					'TODO: this rule does not apply for constructor operation 
					if globalLogLevelIsWarning then
						if not Left(currentOperation.Name,1) = LCase(Left(currentOperation.Name,1)) then 
							Session.Output("Warning: Operation name [" & currentOperation.Name & "] in class ["&currentElement.Name&"] should not start with capital letter. [ISO19103:2015 Recommendation 11]") 
							globalWarningCounter = globalWarningCounter + 1 
						end if 
					end if
 								 
					'check if there is a definition for the operation (call CheckDefinition function) 
					'call the subroutine with currentOperation as parameter 
					CheckDefinition(currentOperation) 
 																 
				next 
			end if					 
		end if 
  	next 
end sub 
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------

'------------------------------------------------------------START-------------------------------------------------------------------------------------------
' Sub Name: FindInvalidElementsInPackage19103Rules
' Author: Kent Jonsrud, Magnus Karge...
' Purpose: Main loop iterating all elements in the selected package and conducting tests on those elements. All tests based on 19103 rules.

sub FindInvalidElementsInPackage19103Rules(package) 
			
 	dim elements as EA.Collection 
 	set elements = package.Elements 'collection of elements that belong to this package (classes, notes... BUT NO packages) 
 	Dim myDictionary 
 	dim errorsInFunctionTests 
 			 
 	'check package definition 
 	CheckDefinition(package) 
			 
	'Iso 19103 Requirement 15 - known stereotypes for packages. - warning if not a standardised stereotype
	'this is not implemented as an error since there can be reasons for new stereotypes with different meaning than the standardised stereotypes
	if UCase(package.element.Stereotype) <> "LEAF" and UCase(package.element.Stereotype) <> "" then
		if globalLogLevelIsWarning then
			Session.Output("Warning: Unknown package stereotype: [«" &package.element.Stereotype& "» " &package.Name& "]. [ISO19103 Requirement 15]")
			globalWarningCounter = globalWarningCounter + 1
		end if	
	end if

	call checkSubPackageStereotype(package)
	
	'Iso 19103 Requirement 16 - unique (NC?)Names on subpackages within the package.
	if ClassAndPackageNames.IndexOf(UCase(package.Name),0) <> -1 then
		Session.Output("Error: Package [" &startPackageName& "] has non-unique subpackage name ["&package.Name&"]. [ISO19103:2015 Requirement 16]")				
		globalErrorCounter = globalErrorCounter + 1 
	end if

	ClassAndPackageNames.Add UCase(package.Name)

	'check if the package name is written correctly according to [ISO19103:2015 recommendation 11]
	checkElementName(package)
 			 
	dim packageTaggedValues as EA.Collection 
	set packageTaggedValues = package.Element.TaggedValues 
 			
	dim packages as EA.Collection 
	set packages = package.Packages 'collection of packages that belong to this package	
			
	'Navigate the package collection and call the FindInvalidElementsInPackage19103Rules function for each of them 
	dim p 
	for p = 0 to packages.Count - 1 
		dim currentPackage as EA.Package 
		set currentPackage = packages.GetAt( p ) 
		FindInvalidElementsInPackage19103Rules(currentPackage) 
		
	next 
 			 
 	'------------------------------------------------------------------ 
	'---ELEMENTS--- 
	'------------------------------------------------------------------		 
 			 
	' Navigate the elements collection, pick the classes, find the definitions/notes and do sth. with it 
	dim i 
	for i = 0 to elements.Count - 1 
		dim currentElement as EA.Element 
		set currentElement = elements.GetAt( i ) 
				
					
		'Is the currentElement of type Class and stereotype codelist or enumeration, check the initial values are numeric or not ([ISO19103:2015 Recommendation 1])
		if ((currentElement.Type = "Class") and (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION") Or currentElement.Type = "Enumeration") then
			call checkNumericinitialValues(currentElement)
		end if

		' check if inherited stereotypes are all the same
		Call requirement14(currentElement)
		
		' ---ALL CLASSIFIERS---
		'Iso 19103 Requirement 16 - unique NCNames of all properties within the classifier.
		'Inherited properties  also included, strictly not an error situation but implicit redefinition is not well supported anyway
		if currentElement.Type = "Class" or currentElement.Type = "DataType" or currentElement.Type = "Enumeration" or currentElement.Type = "Interface" then
			if ClassAndPackageNames.IndexOf(UCase(currentElement.Name),0) <> -1 then
				Session.Output("Error: Class [«" &currentElement.Stereotype& "» "&currentElement.Name&"] in package: [" &package.Name& "] has non-unique name. [ISO19103:2015 Requirement 16]")				
				globalErrorCounter = globalErrorCounter + 1 
			end if

			ClassAndPackageNames.Add UCase(currentElement.Name)

			call requirement16UniqueNCname(currentElement)
		else
			' ---OTHER ARTIFACTS--- Do their names also need to be tested for uniqueness? (need to be different?)
			if currentElement.Type <> "Note" and currentElement.Type <> "Text" and currentElement.Type <> "Boundary" then
				if ClassAndPackageNames.IndexOf(UCase(currentElement.Name),0) <> -1 then
					Session.Output("Debug: Unexpected unknown element with non-unique name [«" &currentElement.Stereotype& "» " &currentElement.Name& "]. EA-type: [" &currentElement.Type& "]. [ISO19103:2015 Requirement 16]")
					'This test is dependent on where the artifact is in the test sequence 
				end if
			end if
		end if
				
		
		'If the currentElement is of type Class, Enumeration or DataType continue conducting some tests. If not continue with the next element. 
		if currentElement.Type = "Class" Or currentElement.Type = "Enumeration" Or currentElement.Type = "DataType" then 
 									 
			'------------------------------------------------------------------ 
			'---CLASSES---ENUMERATIONS---DATATYPE  								'   classifiers ???
			'------------------------------------------------------------------		 
			
			'add name and elementID of the featureType (class, datatype, enumeration with stereotype <<featureType>>) to the related array variables in order to check if the names are unique
			if UCase(currentElement.Stereotype) = "FEATURETYPE" then
				FeatureTypeNames.Add(currentElement.Name)
				FeatureTypeElementIDs.Add(currentElement.ElementID)
			end if
			
			'Iso 19103 Requirement 6 - NCNames in codelist codes.
			if (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" Or currentElement.Type = "Enumeration") then
				call requirement6(currentElement)
			end if

			'Iso 19103 Requirement 7 - definition of codelist codes.
			if (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" or currentElement.Type = "Enumeration") then
				call requirement7CodeDefinition(currentElement)
			end if
	
			'Iso 19103 Requirement 15 - known stereotypes for classes - warning if not a standardised stereotype
			'this is not implemented as an error since there can be reasons for new stereotypes with different meaning than the standardised stereotypes
			if currentElement.Stereotype = "" Or UCase(currentElement.Stereotype) = "FEATURETYPE"  Or UCase(currentElement.Stereotype) = "DATATYPE" Or UCase(currentElement.Stereotype) = "UNION" or UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" Or UCase(currentElement.Stereotype) = "ESTIMATED" or UCase(currentElement.Stereotype) = "MESSAGETYPE"  Or UCase(currentElement.Stereotype) = "INTERFACE" Or currentElement.Type = "Enumeration" then
			else
				if globalLogLevelIsWarning then
					Session.Output("Warning: Class [«" &currentElement.Stereotype& "» " &currentElement.Name& "] has unknown stereotype. [ISO19103 Requirement 15]")
					globalWarningCounter = globalWarningCounter + 1
				end if	
			end if

			'Iso 19103 Requirement 15 - known stereotypes for attributes. 
			call checkKnownStereotypes(currentElement)

			'Iso 19103 Requirements 22 and 25
			if (UCase(currentElement.Stereotype) = "CODELIST"  Or UCase(currentElement.Stereotype) = "ENUMERATION" Or currentElement.Type = "Enumeration") then
				'codelist code type shall be empty, <none> or <undefined>
			else
				call requirement25(currentElement)
			end if

			'Iso 19103 Requirement 18 - each classifier must show all its (inherited) properties together in at least one diagram.
			call requirement18(currentElement)

			'check if there is a definition for the class element (call CheckDefinition function) 
			CheckDefinition(currentElement) 
 										 
			'initialize the global variable startClass which is needed in subroutine findMultipleInheritance 
			set startClass = currentElement 
 					 
				
			'check if the class name is written correctly according to [ISO19103:2015 recommendation 11]
			checkElementName(currentElement)
 											
			if ((currentElement.Type = "Class") and (UCase(currentElement.Stereotype) = "CODELIST")) then
				'Check if an external codelist has a codeList tag that is not empty. 19103 recommendation 4
				Call CheckCodelistTV(currentElement, "codeList")
			end if 
					
					
			dim stereotype
			stereotype = currentElement.Stereotype 
 					
				
			'------------------------------------------------------------------ 
			'---ATTRIBUTES--- 
			'------------------------------------------------------------------					 
 						 
			' Retrieve all attributes for this element 
			dim attributesCollection as EA.Collection 
			set attributesCollection = currentElement.Attributes 
 			 
			if attributesCollection.Count > 0 then 
				dim n 
				for n = 0 to attributesCollection.Count - 1 					 
					dim currentAttribute as EA.Attribute		 
					set currentAttribute = attributesCollection.GetAt(n) 
					'check if the attribute has a definition									 
					'Call the subfunction with currentAttribute as parameter 
					CheckDefinition(currentAttribute) 
																				
					'check if the attribute's name is written correctly according to [ISO19103:2015 recommendation 11], meaning attribute name does not start with capital letter
					checkElementName(currentAttribute)
																								
					'constraints 
					dim constraintACollection as EA.Collection 
					set constraintACollection = currentAttribute.Constraints 
 						
				next 
			end if	 
 					 
			'------------------------------------------------------------------ 
			'---ASSOCIATIONS--- 
			'------------------------------------------------------------------ 
 						 
			'retrieve all associations for this element 
			dim connectors as EA.Collection 
			set connectors = currentElement.Connectors 
 					
			'iterate the connectors 
			'Session.Output("Found " & connectors.Count & " connectors for featureType " & currentElement.Name) 
			dim connectorsCounter 
			for connectorsCounter = 0 to connectors.Count - 1 
				dim currentConnector as EA.Connector 
				set currentConnector = connectors.GetAt( connectorsCounter ) 
							
				if currentConnector.Type = "Aggregation" or currentConnector.Type = "Association" then
								
					'target end 
					dim supplierEnd as EA.ConnectorEnd
					set supplierEnd = currentConnector.SupplierEnd
															
					'source end 
					dim clientEnd as EA.ConnectorEnd
					set clientEnd = currentConnector.ClientEnd
									
				end if 		
 							
											
				dim sourceElementID 
				sourceElementID = currentConnector.ClientID 
				dim sourceEndNavigable  
				sourceEndNavigable = currentConnector.ClientEnd.Navigable 
				dim sourceEndName 
				sourceEndName = currentConnector.ClientEnd.Role 
				dim sourceEndDefinition 
				sourceEndDefinition = currentConnector.ClientEnd.RoleNote 
				dim sourceEndCardinality		 
				sourceEndCardinality = currentConnector.ClientEnd.Cardinality 
 							 
				dim targetElementID 
				targetElementID = currentConnector.SupplierID 
				dim targetEndNavigable  
				targetEndNavigable = currentConnector.SupplierEnd.Navigable 
				dim targetEndName 
				targetEndName = currentConnector.SupplierEnd.Role 
				dim targetEndDefinition 
				targetEndDefinition = currentConnector.SupplierEnd.RoleNote 
				dim targetEndCardinality 
				targetEndCardinality = currentConnector.SupplierEnd.Cardinality 
 							
				'if the current element is on the connectors client side conduct some tests 
				'(this condition is needed to make sure only associations where the 
				'source end is connected to elements within this package are  
				'checked. Associations with source end connected to elements outside of this 
				'package are possibly locked and not editable) 
				 							 
				dim elementOnOppositeSide as EA.Element 
				if currentElement.ElementID = sourceElementID and not currentConnector.Type = "Realisation" and not currentConnector.Type = "Generalization" then 
					
										
					set elementOnOppositeSide = Repository.GetElementByID(targetElementID) 
 								 
					'if the connector has a name (optional according to the rules), check if it starts with capital letter [ISO19103:2015 recommendation 11]
					call checkElementName(currentConnector)
					
					'check if elements on both sides of the association are classes with stereotype dataType or of element type DataType
					call checkDataTypeAssociation(currentElement, currentConnector, elementOnOppositeSide)
													
					'check if there is a definition on navigable ends (navigable association roles) of the connector 
					'Call the subfunction with currentConnector as parameter 
					CheckDefinition(currentConnector) 
 																								 
					'check if there is multiplicity on navigable ends ([ISO19103:2015 Requirement 10])
					call checkMultiplicityOnNavigableEnds(currentElement, sourceEndNavigable, targetEndNavigable, sourceEndName, targetEndName, sourceEndCardinality, targetEndCardinality, currentConnector)
					 
					'check if there are role names on navigable ends  ([ISO19103:2015 Requirement 10])
					call checkRoleNamesOnNavigableEnds(currentElement, sourceEndNavigable, targetEndNavigable, sourceEndName, targetEndName, elementOnOppositeSide, currentConnector)
																		 
					'check if role names on connector ends start with lower case (regardless of navigability) 
					call checkRoleNames(currentElement, sourceEndName, targetEndName, elementOnOppositeSide)
					
				end if 
			next 
 						 
			'------------------------------------------------------------------ 
			'---OPERATIONS--- 
			'------------------------------------------------------------------ 
 						 
			' Retrieve all operations for this element 
			dim operationsCollection as EA.Collection 
			set operationsCollection = currentElement.Methods 
 			 
			if operationsCollection.Count > 0 then 
				dim operationCounter 
				for operationCounter = 0 to operationsCollection.Count - 1 					 
					dim currentOperation as EA.Method		 
					set currentOperation = operationsCollection.GetAt(operationCounter) 
 								
					'check if the operations's name starts with lower case 
					'TODO: this rule does not apply for constructor operation 
					if globalLogLevelIsWarning then
						if not Left(currentOperation.Name,1) = LCase(Left(currentOperation.Name,1)) then 
							Session.Output("Warning: Operation name [" & currentOperation.Name & "] in class ["&currentElement.Name&"] should not start with capital letter. [ISO19103:2015 Recommendation 11]") 
							globalWarningCounter = globalWarningCounter + 1 
						end if 
					end if
 								 
					'check if there is a definition for the operation (call CheckDefinition function) 
					'call the subroutine with currentOperation as parameter 
					CheckDefinition(currentOperation) 
 																 
				next 
			end if					 
		end if 
  	next 
end sub 
'-------------------------------------------------------------END--------------------------------------------------------------------------------------------


'global variables 
dim globalRuleSet19109 'boolean variable indicating if rule set from ISO 19109 has been choosen or not
globalRuleSet19109=true 'default setting for rule set from ISO 19109 is true

dim globalLogLevelIsWarning 'boolean variable indicating if warning log level has been choosen or not
globalLogLevelIsWarning = true 'default setting for warning log level is true
 
dim startClass as EA.Element  'the class which is the starting point for searching for multiple inheritance in the findMultipleInheritance subroutine 

dim globalErrorCounter 'counter for number of errors 
globalErrorCounter = 0 
dim globalWarningCounter
globalWarningCounter = 0
'Global list of all used names
'http://sparxsystems.com/enterprise_architect_user_guide/12.1/automation_and_scripting/reference.html
dim startPackageName
dim ClassAndPackageNames
Set ClassAndPackageNames = CreateObject("System.Collections.ArrayList")
'Global objects for testing whether a class is showing all its content in at least one diagram. 19103 requirement 18
dim startPackage as EA.Package
dim diaoList
dim diagList

'List of well known type names defined in iso 19109:2015
dim ProfileTypes
'List of well known extension type names defined in iso 19103:2015
dim ExtensionTypes
'List of well known core type names defined in iso 19103:2015
dim CoreTypes

'two global variables for checking uniqueness of FeatureType names - shall be updated in sync 
dim FeatureTypeNames 
Set FeatureTypeNames = CreateObject("System.Collections.ArrayList")
dim FeatureTypeElementIDs
Set FeatureTypeElementIDs = CreateObject("System.Collections.ArrayList")

'global variable containing list of the starting package and all subpackages
dim globalPackageIDList
set globalPackageIDList=CreateObject("System.Collections.ArrayList")

'global variable containing list of all classifier ids within the application schema
dim globalListAllClassifierIDsInApplicationSchema
set globalListAllClassifierIDsInApplicationSchema=CreateObject("System.Collections.ArrayList")

'global variable containing list of all classifier ids of elements not part of the application schema but
'referenced from elements within the application schema 
dim globalListClassifierIDsOfExternalReferencedElements
set globalListClassifierIDsOfExternalReferencedElements=CreateObject("System.Collections.ArrayList")

'global variable containing list of pckage IDs to be referenced
dim globalListPackageIDsOfPackagesToBeReferenced
set globalListPackageIDsOfPackagesToBeReferenced=CreateObject("System.Collections.ArrayList")

'global variable containing list of package element IDs of modelled dependencies
dim globalListPackageElementIDsOfPackageDependencies
set globalListPackageElementIDsOfPackageDependencies=CreateObject("System.Collections.ArrayList")



OnProjectBrowserScript 
