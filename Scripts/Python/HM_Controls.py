from EAConnect import *
import pandas as pd

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
        printTS('Diagram: ' + eaDgr.Name)
        printTS('Number of objects: ' + str(eaDgr.DiagramObjects.Count))
        printTS('Setting element fonts to Cambria')
        for eaDgrObj in eaDgr.DiagramObjects:
            # Set all fonts to Cambria

            if 'font=' in eaDgrObj.Style:
                # printTS('Object style: ' + eaDgrObj.Style)
                new_text = replace_all_fonts(eaDgrObj.Style)
                # printTS('New style: ' + new_text)
                eaDgrObj.Style = new_text
                eaDgrObj.Update()

        printTS('Hiding "isSubstitutable" labels')
        for eaDrgLink in eaDgr.DiagramLinks:
            # Hide the "isSubstitutable" label (Middle Bottom Label, LMB)

            if 'LMB=' in eaDrgLink.Geometry:
                #Check and replace substring HDN=0 with HDN=1
                if 'HDN=0' in eaDrgLink.Geometry:
                    # printTS('Diagramlink style: ' + eaDrgLink.Geometry)
                    new_text = hideLMB(eaDrgLink.Geometry)
                    eaDrgLink.Geometry = new_text
                    eaDrgLink.Update()

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

def listClassifiers(eaRepo,pck,df):
    #List vlassifiers for attributes and association ends
    #First, build list of all elements in 19103 and current package, to help fixing missing classifiers 
    elDict = {}
    #List all elements in 19103
    try:
        elPck = eaRepo.GetPackageByGuid(guidISO19103)
        elDict = recListElements(elPck,elDict)      
    except:
        printTS('ISO 19103 package not found') 
        # List all elements in current package
    elDict = recListElements(pck,elDict)    
    
    # List and fix classifisers for current package  
    df =  recListClassifiers(eaRepo,pck,elDict,df)
    return df

def recListClassifiers(eaRepo, pck,elDict,df):
    # Recursive loop through subpackages and their elements, with controll of attributes
    fullPath = namespaceString(eaRepo,pck.Element)
    #printTS('INFO|Package namespace: ' + fullPath)
    for eaEl in pck.Elements:
        #printTS('INFO|Element: ' + eaEl.Stereotype + " " + eaEl.Name)
        if eaEl.Type.upper() in ["CLASS","INTERFACE", "DATATYPE"] and not eaEl.Stereotype.upper() in ["CODELIST","ENUMERATION"]:
            for eaAttr in eaEl.Attributes:
                #printTS('INFO|Attribute: ' + eaAttr.Name)
                if eaAttr.ClassifierID == 0:
                    #For primitive 19103 types: Fix references
                    if eaAttr.Type in elDict:
                        guidDT = elDict[eaAttr.Type]
                        eaDTel = eaRepo.GetElementByGuid(guidDT)
                        eaAttr.ClassifierID = eaDTel.ElementID  
                        eaAttr.Update()
                        printTS('INFO|Fixing referenced element for attribute: ' + pStr + '.' + eaDTel.Name + ' (GUID = ' + guidDT + ')')
                if eaAttr.ClassifierID != 0:
                    try:
                        cEl = eaRepo.GetElementByID(eaAttr.ClassifierID)
                        pStr = namespaceString(eaRepo,cEl)
                        # printTS('INFO|Referenced element for attribute: ' + pStr + '.' + cEl.Name + ' (GUID = ' + cEl.ElementGUID + ')')
                        #Add namespace etc to Dependencies list
                        df.loc[len(df)] = [fullPath,pck.Name,eaEl.Name,eaAttr.Name,pStr,cEl.Name,cEl.ElementGUID]
                    except Exception as e:
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

def listMissingDefinitions(eaRepo,pck,defDf):
    #List missing definitions
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
                if eaAttr.Notes == "":
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
        recListClassifiers(eaRepo,sPck,defDf)

    return defDf