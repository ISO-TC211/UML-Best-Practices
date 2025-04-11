from EAConnect import *
import pandas as pd
import re 

def replace_all_fonts(text, new_font="Cambria"):
  parts = text.split(';')
  for i, part in enumerate(parts):
    if part.lower().startswith('font='):
      parts[i] = f"font={new_font}"  # Use f-string for direct insertion
  return ';'.join(parts)

def hideLMB(text):
    parts = text.split(';')
    for i, part in enumerate(parts):
        if part.startswith('LMB='):
            subparts = parts[i].split(':')
            for j, subpart in enumerate(subparts):
                if subpart == 'HDN=0':
                    subparts[j] = f"HDN=1"  # Use f-string for direct insertion
            parts[i] = ':'.join(subparts)        
    return ';'.join(parts)

def recDiagramCleaning(pck):
    #Loop through diagrams in the package. Set font to Cambria and hide "isSubstituable" labels
    printTS('Diagram count: ' + str(pck.Diagrams.Count))
    for eaDgr in pck.Diagrams:
        printTS('Diagram: ' + eaDgr.Name + ' (' + str(eaDgr.DiagramObjects.Count) + ' objects)') 
        #printTS('Setting element fonts to Cambria')
        for eaDgrObj in eaDgr.DiagramObjects:
            # Set all fonts to Cambria

            if 'font=' in eaDgrObj.Style:
                # printTS('Object style: ' + eaDgrObj.Style)
                new_text = replace_all_fonts(eaDgrObj.Style)
                # printTS('New style: ' + new_text)
                eaDgrObj.Style = new_text
                eaDgrObj.Update()

        #printTS('Hiding "isSubstitutable" labels')
        for eaDrgLink in eaDgr.DiagramLinks:
            # Hide the "isSubstitutable" label (Middle Bottom Label, LMB)
            geometry = eaDrgLink.Geometry
            if 'LMB=' in geometry:
                # If not set --> change 'LMB=;' to 'LMB=HDN=1'
                geometry = geometry.replace("LMB=;", "LMB=HDN=1;")
                # If set --> Check and replace substring HDN=0 with HDN=1
                if 'HDN=0' in geometry:
                    # printTS('Diagramlink style: ' + eaDrgLink.Geometry)
                    geometry = hideLMB(geometry)
                eaDrgLink.Geometry = geometry
                eaDrgLink.Update()        

        #TODO: Set theme to ISO/TC 211
        newStyleEx = re.sub(r"Theme=[^:]*:", "Theme=ISO/TC 211:", eaDgr.StyleEx)
        #If errorneous setting from old script:
        #newStyleEx = eaDgr.StyleEx.replace("Theme=ISO/TC 211;", "Theme=ISO/TC 211:119;")
        eaDgr.StyleEx = newStyleEx
        eaDgr.Update()

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recDiagramCleaning(sPck)

def namespaceString(eaRepo,e):
    #Loop to get the complete namespace for an element
    try:
        elP = eaRepo.GetPackageByID(e.PackageID)
        namespaceString = elP.Name
        parentId =  elP.ParentID
        while parentId != 0:
            elP = eaRepo.GetPackageByID(parentId)
            parentId = elP.ParentID
            if parentId != 0:
                namespaceString = elP.Name + "." + namespaceString
    except:
        printTS('Referenced element not in the repository')  
        namespaceString = ''
    return namespaceString

def recListElements(p,elDict):
    #Create a dictionary with all elements and their GUIDs in a package and subpackages
    for eaEl in p.Elements:
        if eaEl.Type.upper() in ['CLASS','DATATYPE','INTERFACE','ENUMERATION']:
            elDict[eaEl.Name] = eaEl.ElementGUID

    #Traverse the package structure
    for sPck in p.Packages:
        # printTS('----------------------------')
        # printTS('Package: ' + sPck.Name)
        recListElements(sPck,elDict)

    return elDict    

def listClassifiers(eaRepo,pck,fix=True):
    #List classifiers for attributes and association ends
    #First, build list of all elements in 19103 and current package, to help fixing missing classifiers 
    elDict = {}
    #List all elements in 19103
    try:
        elPck = eaRepo.GetPackageByGuid(guidISO19103)
        elDict = recListElements(elPck,elDict)    
        #Extra for ISO 19130-2: Include ISO 19130-1 in dictionary
        elPck = eaRepo.GetPackageByGuid('{64043AD9-1FCA-4b4b-A771-C8E96CA5E068}')
        elDict = recListElements(elPck,elDict)
        #Include ISO 19107 in dictionary
        elPck = eaRepo.GetPackageByGuid('{333A3E17-51C9-45a2-9EDF-19CE0CF1E198}')
        elDict = recListElements(elPck,elDict)             
    except:
        printTS('Package not found') 
    # List all elements in current package
    elDict = recListElements(pck,elDict)    
    
    # List and fix classifisers for current package  
    df = pd.DataFrame(columns=['FullPath','Package','Element','Property','DependentPackage','DependentElement','GUID'])
    df =  recListClassifiers(eaRepo,pck,elDict,df)
    return df

def process_string(s):
    # Check if the string ends with '[n]'
    if s.endswith('[n]'):
        strType = s[:-3]
        lower = '0'
        upper = '*'
    else:
        # Check if the string has a number within the brackets
        match = re.search(r'\[(\d+)\]$', s)
        if match:
            strType = s[:match.start()]
            number = match.group(1)
            lower = number
            upper = number
        else:
            # Check if the string has two values delimited by '..' within the brackets
            match = re.search(r'\[(\d+)\.\.(\d+|n|\*)\]$', s)
            if match:
                strType = s[:match.start()]
                lower = match.group(1)
                upper = match.group(2)
                if upper in ['n', '*']:
                    upper = '*'
            else:
                # Check if the string has two values divided by a comma within the brackets
                match = re.search(r'\[(\d+),(\d+)\]$', s)
                if match:
                    strType = s[:match.start()]
                    lower = match.group(1)
                    upper = match.group(2)
                else:
                    # Check if the string has two values delimited by '*' within the brackets
                    match = re.search(r'\[(\d+)\*(\d+|n)\]$', s)
                    if match:
                        strType = s[:match.start()]
                        lower = match.group(1)
                        upper = match.group(2)
                        if upper == 'n':
                            upper = '*'
                    else:
                        # If no pattern matches, return None
                        return None
    return strType, lower, upper
    
def recListClassifiers(eaRepo, pck,elDict,df,fix=True):
    # Recursive loop through subpackages and their elements, with controll of attributes
    fullPath = namespaceString(eaRepo,pck.Element)
    printTS('INFO|Package namespace: ' + fullPath)
    for eaEl in pck.Elements:
        #printTS('INFO|Element: ' + eaEl.Stereotype + " " + eaEl.Name)
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE"] and not eaEl.Stereotype.upper() in ["CODELIST","ENUMERATION"]:
            for eaAttr in eaEl.Attributes:
                eaAttr.Visibility = 'Public'
                eaAttr.Update()
                #printTS('INFO|Attribute: ' + eaAttr.Name)
                if eaAttr.Type.upper() == 'CHARACTERSTRING': 
                    eaAttr.Type = 'CharacterString'
                    eaAttr.Update()
                if eaAttr.Type.upper() == 'DECIMAL': 
                    eaAttr.Type = 'Real'
                    eaAttr.Update()                
                if eaAttr.Type != '':
                    #if eaAttr.ClassifierID == 0 and fix:
                    if fix:                    
                        #For primitive 19103 types: Fix references
                        if eaAttr.Type in elDict:
                            guidDT = elDict[eaAttr.Type]
                            eaDTel = eaRepo.GetElementByGuid(guidDT)
                            eaAttr.ClassifierID = eaDTel.ElementID  
                            eaAttr.Update()
                            printTS('INFO|Fixing referenced element for attribute: ' + fullPath + '.' + eaDTel.Name + ' (GUID = ' + guidDT + ')')
                    if eaAttr.ClassifierID != 0:
                        try:
                            cEl = eaRepo.GetElementByID(eaAttr.ClassifierID)
                            pStr = namespaceString(eaRepo,cEl)
                            # printTS('INFO|Referenced element for attribute: ' + pStr + '.' + cEl.Name + ' (GUID = ' + cEl.ElementGUID + ')')
                            #Add namespace etc to Dependencies list
                            df.loc[len(df)] = [fullPath,pck.Name,eaEl.Name,eaAttr.Name,pStr,cEl.Name,cEl.ElementGUID]
                        except Exception as e:
                            eaAttr.ClassifierID = 0
                            eaAttr.Update()
                            printTS('ERROR|' + str(e))    
                    else:
                        # Still missing classifier
                        printTS('ERROR|Missing data type connection for attribute :' + eaEl.Name + '.' + eaAttr.Name + ' (Data type: ' + eaAttr.Type + ')')
                        #Add namespace, attribute name and data type to Error data frame
                        df.loc[len(df)] = [fullPath,pck.Name,eaEl.Name,eaAttr.Name,None, eaAttr.Type, None]

            #Loop for connector dependencies
            for eaCon in eaEl.Connectors:
                if eaCon.SupplierID == eaEl.ElementID:
                    cEl = eaRepo.GetElementByID(eaCon.ClientID)
                    cEnd = eaCon.ClientEnd
                else:
                    cEl = eaRepo.GetElementByID(eaCon.SupplierID)
                    cEnd = eaCon.SupplierEnd

                pStr = namespaceString(eaRepo,cEl)
                if cEnd.Role == "":
                    strRole = eaCon.Type
                else:
                    strRole = cEnd.Role   

                #Add namespace etc to Dependencies list
                df.loc[len(df)] = [fullPath,pck.Name,eaEl.Name,strRole,pStr,cEl.Name,cEl.ElementGUID]

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recListClassifiers(eaRepo,sPck,elDict,df)

    return df    

def listAllDefinitions(eaRepo,pck):
    #List all definitions
    defDf = pd.DataFrame(columns=['GUID','Type','PackageName','ElementName','PropertyName','Supplier','Definition'])
    recListAllDefinitions(eaRepo,pck,defDf)
    return defDf

def recListAllDefinitions(eaRepo,pck,defDf):
    #Recursive loop for missing definitons
    for eaEl in pck.Elements:
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE","ENUMERATION"]:
            defDf.loc[len(defDf)] = [eaEl.ElementGUID, eaEl.Type,pck.Name,eaEl.Name,None,None, eaEl.Notes]
            for eaAttr in eaEl.Attributes:   
                if eaEl.Stereotype.upper() in ["CODELIST","ENUMERATION"]:
                    defDf.loc[len(defDf)] = [eaAttr.AttributeGUID,'Code value',pck.Name,eaEl.Name,eaAttr.Name,None,eaAttr.Notes]
                else:
                    defDf.loc[len(defDf)] = [eaAttr.AttributeGUID,'Attribute',pck.Name,eaEl.Name,eaAttr.Name,None,eaAttr.Notes]

            #Loop for connector end definitions
            for eaCon in eaEl.Connectors:
                if eaCon.Type in ["Aggregation","Association"]:
                    if eaCon.SupplierID == eaEl.ElementID:
                        cEnd = eaCon.ClientEnd
                        oppositeElId = eaCon.ClientID
                    else:
                        cEnd = eaCon.SupplierEnd
                        oppositeElId = eaCon.SupplierID
                    cEl = eaRepo.GetElementByID(oppositeElId)

                    if cEnd.Navigable == "Navigable":
                        defDf.loc[len(defDf)] = [eaCon.ConnectorGUID,'Role name',pck.Name,eaEl.Name,None,cEl.Name, None]
                        defDf.loc[len(defDf)] = [eaCon.ConnectorGUID,'Role',pck.Name,eaEl.Name,cEnd.Role,cEl.Name, cEnd.RoleNote]

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recListAllDefinitions(eaRepo,sPck,defDf)

    return defDf


def listMissingDefinitions(eaRepo,pck):
    #List missing definitions
    defDf = pd.DataFrame(columns=['Type','PackageName','ElementName','PropertyName','Supplier'])
    recListMissingDefinitions(eaRepo,pck,defDf)
    return defDf

def recListMissingDefinitions(eaRepo,pck,defDf):
    #Recursive loop for missing definitons
    for eaEl in pck.Elements:
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE","ENUMERATION"]:
            if eaEl.Notes == "":
                printTS('ERROR|Missing definition for:' + eaEl.Type + ' in package ' + pck.Name + ':' + eaEl.Name)
                #Add to missing definitions list
                defDf.loc[len(defDf)] = [eaEl.Type,pck.Name,eaEl.Name,None,None]
            for eaAttr in eaEl.Attributes:   
                if eaAttr.Notes == "" or eaAttr.Notes == "<memo>":
                    if eaEl.Stereotype.upper() in ["CODELIST","ENUMERATION"]:
                        printTS('ERROR|Missing definition for code value in package ' + pck.Name + ': ' + eaEl.Name + "." + eaAttr.Name)
                        #Add to missing definitions list
                        defDf.loc[len(defDf)] = ['Code value',pck.Name,eaEl.Name,eaAttr.Name,None]
                    else:
                        printTS('ERROR|Missing definition for attribute in package ' + pck.Name + ': ' + eaEl.Name + "." + eaAttr.Name)                            
                        defDf.loc[len(defDf)] = ['Attribute',pck.Name,eaEl.Name,eaAttr.Name,None]

            #Loop for connector end definitions
            for eaCon in eaEl.Connectors:
                if eaCon.Type in ["Aggregation","Association"]:
                    if eaCon.SupplierID == eaEl.ElementID:
                        cEnd = eaCon.ClientEnd
                        oppositeElId = eaCon.ClientID
                    else:
                        cEnd = eaCon.SupplierEnd
                        oppositeElId = eaCon.SupplierID
                    cEl = eaRepo.GetElementByID(oppositeElId)

                    if cEnd.Navigable == "Navigable" and cEnd.Role == "":
                        printTS('ERROR|Missing role name for ' + cEnd.Navigable + ' association in package ' + pck.Name + ': ' + eaEl.Name + ' towards ' + cEl.Name)                            
                        defDf.loc[len(defDf)] = ['Role name',pck.Name,eaEl.Name,None,cEl.Name]
                        if cEnd.Navigable == "Navigable" and cEnd.RoleNote =="":
                                printTS('ERROR|Missing role definition for ' + cEnd.Navigable + ' association in package ' + pck.Name + ': ' + eaEl.Name + ' towards ' + cEl.Name)                            
                                defDf.loc[len(defDf)] = ['Role',pck.Name,eaEl.Name,None,cEl.Name]
                    if cEnd.Navigable == "Navigable" and cEnd.RoleNote =="" and cEnd.Role != "":
                            printTS('ERROR|Missing role definition for ' + cEnd.Navigable + ' association in package ' + pck.Name + ': ' + eaEl.Name + "." + cEnd.Role + ' towards ' + cEl.Name)                            
                            defDf.loc[len(defDf)] = ['Role',pck.Name,eaEl.Name,cEnd.Role,cEl.Name]

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recListMissingDefinitions(eaRepo,sPck,defDf)

    return defDf

def duplicateElements(pck):
    #Check for duplicate elements
    df = pd.DataFrame(columns=['PackageName','ElementName','Type'])
    recDuplicateElements(pck,df)    
    return df

def recDuplicateElements(pck, df):
    #Check for duplicate elements
    for eaEl in pck.Elements:
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE","ENUMERATION"]:
           if eaEl.Name in df['ElementName'].values:
               printTS('ERROR|Duplicate element: ' + eaEl.Name)
           df.loc[len(df)] = [pck.Name,eaEl.Name,eaEl.Type] 
    
    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recDuplicateElements(sPck, df)

    return df    

def elementsInDiagrams(pck):
    #Check that all elements are in diagrams
    dfD = pd.DataFrame(columns=['DiagramName','ElementID'])
    dfD = recDiagramObjects(pck,dfD)
    dfE = pd.DataFrame(columns=['PackageName','ElementName','Type','GUID'])
    recElementsInDiagrams(pck,dfD, dfE)    
    return dfE

def recDiagramObjects(pck, dfD):
    #List all diagrams and their objects
    for eaDgr in pck.Diagrams:
        printTS('Diagram: ' + eaDgr.Name + ' (' + str(eaDgr.DiagramObjects.Count) + ' objects)') 
        for eaDgrObj in eaDgr.DiagramObjects:
            dfD.loc[len(dfD)] = [eaDgr.Name,eaDgrObj.ElementID] 

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recDiagramObjects(sPck, dfD)

    return dfD  

def recElementsInDiagrams(pck, dfD, dfE):
    #Check for missing elements
    for eaEl in pck.Elements:
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE","ENUMERATION"]:
            if not eaEl.ElementID in dfD['ElementID'].values:
                printTS('ERROR|Element not in any diagram: ' + eaEl.Type + ' ' + pck.Name + '.' + eaEl.Name)
                dfE.loc[len(dfE)] = [pck.Name,eaEl.Name,eaEl.Type,eaEl.ElementGUID]

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recElementsInDiagrams(sPck, dfD,dfE)

    return dfE  

def fixCSL(eaRepo,pck):
    #Fix data types and classifier types for 19103 
    #First, build list of all elements in 19103, to help fixing core types
    elDict = {}
    #List all elements in 19103
    try:
        elPck = eaRepo.GetPackageByGuid(guidISO19103)
        elDict = recListElements(elPck,elDict)      
    except:
        printTS('ISO 19103 package not found') 
     
    # List and fix classifisers for current package  
    df = pd.DataFrame(columns=['FullPath','Package','Element','Property','DependentPackage','DependentElement','GUID'])
    df =  recfixCSL(eaRepo,pck,elDict,df)
    return df

def recfixCSL(eaRepo, pck,elDict,df,fix=True):
    # Recursive loop through subpackages and their elements, with upgrade to ISO 19103 Ed2
    fullPath = namespaceString(eaRepo,pck.Element)
    #printTS('INFO|Package namespace: ' + fullPath)
    for eaEl in pck.Elements:
        #printTS('INFO|Element: ' + eaEl.Stereotype + " " + eaEl.Name)
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE"] and not eaEl.Stereotype.upper() in ["CODELIST","ENUMERATION"]:
             for eaAttr in eaEl.Attributes:            
                #For primitive 19103 types: Fix references
                if eaAttr.Type in elDict:
                    guidDT = elDict[eaAttr.Type]
                    eaDTel = eaRepo.GetElementByGuid(guidDT)
                    if eaAttr.ClassifierID != eaDTel.ElementID:
                        eaAttr.ClassifierID = eaDTel.ElementID  
                        eaAttr.Update()
                        printTS('INFO|Fixing referenced element for attribute: ' + fullPath + '.' + eaDTel.Name + ' (GUID = ' + guidDT + ')')
                #Stereotype for attributes and association end: GI_Property
                eaAttr.StereotypeEx = ''
                eaAttr.Stereotype = 'ISO19103::GI_Property'
                eaAttr.Update()

             for eaCon in eaEl.Connectors:
                 cEnd = eaCon.ClientEnd
                 if cEnd.Role != '':
                    cEnd.StereotypeEx = ''
                    cEnd.Stereotype = 'ISO19103::GI_Property'
                    cEnd.Update()
                 sEnd = eaCon.SupplierEnd
                 if sEnd.Role != '':
                    sEnd.StereotypeEx = ''
                    sEnd.Stereotype = 'ISO19103::GI_Property'
                    sEnd.Update()

            

        if eaEl.Type.upper() == 'CLASS' and 'FEATURE TYPE' in eaEl.StereotypeEx.upper():
            eaEl.StereotypeEx = ''
            eaEl.Stereotype = 'ISO19109::FeatureType'
            eaEl.Update()
            printTS('INFO|Fixing stereotype for element: ' + fullPath + '.' + eaEl.Name)
        elif eaEl.Type.upper() == 'CLASS' and eaEl.Stereotype == '':
            eaEl.StereotypeEx = ''
            eaEl.Stereotype = 'ISO19103::GI_Class'
            eaEl.Update()
            printTS('INFO|Fixing stereotype for element: ' + fullPath + '.' + eaEl.Name)

        elif eaEl.Type.upper() == 'CLASS' and eaEl.Stereotype.upper() == 'DATATYPE':
            eaEl.Type = 'DataType'
            eaEl.StereotypeEx = ''
            eaEl.Stereotype = 'ISO19103::GI_DataType'
            eaEl.Update()
            printTS('INFO|Fixing stereotype for element: ' + fullPath + '.' + eaEl.Name)
        elif eaEl.Type.upper() == 'DATATYPE' and 'DATA TYPE' in eaEl.StereotypeEx.upper():
            eaEl.StereotypeEx = ''
            eaEl.Stereotype = 'ISO19103::GI_DataType'
            eaEl.Update()
            printTS('INFO|Fixing stereotype for element: ' + fullPath + '.' + eaEl.Name)
        
        elif eaEl.Type.upper() == 'CLASS' and eaEl.Stereotype.upper() == 'CODELIST':
            eaEl.Type = 'DataType'
            eaEl.StereotypeEx = ''
            eaEl.Stereotype = 'ISO19103::GI_CodeSet'
            eaEl.Update()
            printTS('INFO|Fixing stereotype for element: ' + fullPath + '.' + eaEl.Name)            

        else:
            printTS('INFO|Element type not handled for upgrade: ' + eaEl.Stereotype + ' ' + fullPath + '.' + eaEl.Name)            
        # TODO: Enumeration --> GI_Enumeration
        # TODO: Interface --> GI_Interface or GI_Class
        
    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
        printTS('Package: ' + sPck.Name)
        recfixCSL(eaRepo,sPck,elDict,df)

    return df    