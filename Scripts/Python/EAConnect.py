import win32com.client as win32
from datetime import datetime
from Parameters import *
import sys

def printTS(message):
    # Print a message with a timestamp
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    # Print the message with the timestamp
    print(timestamp, " ", message)

def openEAapp():
    #Open EA 
    # On error: Remove "C:\Users\JETKNU\AppData\Local\Temp\gen_py"
    printTS('Hi EA - are you there? ')
    eaApp = win32.gencache.EnsureDispatch('EA.App')
    printTS('I am here')
    return eaApp

def openEArepo(eaApp,repo_path):
    #Open the EA Repository
    eaRepo = eaApp.Repository
    printTS('Hi EA - Please open this repository: ' + repo_path )
    # Open the repository
    try: 
        eaRepo.SuppressSecurityDialog = True
        eaRepo.OpenFile2(repo_path,"","")
        printTS("OK! Repository " + repo_path + " is ready!")
        return eaRepo
    except Exception as e:
        printTS(e)

def closeEA(eaRepo):
    # Close the repository and exit EA
    eaRepo.CloseFile()
    eaRepo.Exit()   
    printTS('Repository closed!')
 
def getElementByName(eaPck,strName):
# Get element by name, or create if not existing
    
    try:
        eaEl = eaPck.Elements.GetByName(strName)
    except:    
        eaEl = None
    if eaEl != None:
        printTS('Existing Element "' + eaEl.Name + '"')
    return eaEl

def getClassifierFromDictionary(eaRepo,eaAttr,strType):
#Set references for primitive ISO/TC 211 UML types
    if strType in dtDict:
        guidDT = dtDict[strType]
        try:
            eaDTel = eaRepo.GetElementByGuid(guidDT)
            eaAttr.ClassifierID = eaDTel.ElementID  
        except:
            printTS('Referenced element not in the repository')      
    eaAttr.Update()
    return eaAttr     

# --------- Test code ----------------




